import Foundation
import VaktijaCore

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case iconOnly
    case fullCountdown
    case compactCountdown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .iconOnly: "Icon Only"
        case .fullCountdown: "Full Countdown"
        case .compactCountdown: "Compact Countdown"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var menuBarDisplayMode: MenuBarDisplayMode {
        didSet { defaults.set(menuBarDisplayMode.rawValue, forKey: Keys.menuBarDisplayMode) }
    }
    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
            Task { await handleNotificationPreferenceChange() }
        }
    }
    @Published var reminderOffsetMinutes: Int {
        didSet {
            defaults.set(reminderOffsetMinutes, forKey: Keys.reminderOffsetMinutes)
            Task { await rescheduleNotificationsIfNeeded() }
        }
    }
    @Published var notificationPermissionStatus = "Not Requested"
    @Published private(set) var notificationScheduleStatus = "Disabled"
    @Published private(set) var today: PrayerDay?
    @Published private(set) var tomorrow: PrayerDay?
    @Published private(set) var nextTarget: CountdownTarget?
    @Published private(set) var cacheStatus = "Loading"
    @Published private(set) var now = Date()

    var fullMenuBarTitle: String {
        guard let nextTarget else {
            return "Vaktija"
        }
        return "\(nextTarget.event.rawValue): \(CountdownFormatter.full(duration: nextTarget.duration))"
    }

    var compactMenuBarTitle: String {
        guard let nextTarget else {
            return "Vaktija"
        }
        return CountdownFormatter.compact(event: nextTarget.event, duration: nextTarget.duration)
    }

    let location = PrayerLocation.sarajevo
    let sourceLabel = "AlAdhan 14.6°"

    private enum Keys {
        static let menuBarDisplayMode = "menuBarDisplayMode"
        static let notificationsEnabled = "notificationsEnabled"
        static let reminderOffsetMinutes = "reminderOffsetMinutes"
    }

    private let defaults: UserDefaults
    private let cache: PrayerCache
    private let client = AlAdhanClient()
    private let notificationScheduler = NotificationScheduler()
    private var timer: Timer?

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: location.timeZoneIdentifier) ?? .current
        return calendar
    }

    init(
        defaults: UserDefaults = .standard,
        cache: PrayerCache? = nil
    ) {
        self.defaults = defaults
        self.cache = cache ?? PrayerCache(baseDirectory: Self.defaultCacheDirectory())

        let rawMode = defaults.string(forKey: Keys.menuBarDisplayMode)
        self.menuBarDisplayMode = rawMode.flatMap(MenuBarDisplayMode.init(rawValue:)) ?? .fullCountdown
        self.notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled)
        let storedOffset = defaults.integer(forKey: Keys.reminderOffsetMinutes)
        self.reminderOffsetMinutes = storedOffset == 0 ? 45 : storedOffset

        startTimer()
        Task {
            await updateNotificationPermissionStatus()
            await refreshFromCacheAndNetwork()
        }
    }

    func refreshFromCacheAndNetwork() async {
        do {
            try loadVisibleDaysFromCache()
            cacheStatus = "Cached"
            await rescheduleNotificationsIfNeeded()
        } catch {
            cacheStatus = "Fetching"
        }

        do {
            try await fetchMissingOrInvalidVisibleMonths()

            try loadVisibleDaysFromCache()
            cacheStatus = "Updated"
            await rescheduleNotificationsIfNeeded()

            Task.detached { [cache, client, location] in
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(identifier: location.timeZoneIdentifier) ?? .current
                let warmer = CacheWarmer(fetcher: client, cache: cache, calendar: calendar)
                try? await warmer.warm(location: location, now: Date())
            }
        } catch {
            cacheStatus = today == nil ? "Unavailable" : "Offline Cache"
            await rescheduleNotificationsIfNeeded()
        }
    }

    func displayTime(_ components: DateComponents?) -> String {
        guard let hour = components?.hour, let minute = components?.minute else {
            return "--:--"
        }
        return String(format: "%02d:%02d", hour, minute)
    }

    func openNotificationSettings() {
        notificationScheduler.openNotificationSettings()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func tick() {
        let previousNow = now
        now = Date()
        updateNextTarget()

        if !calendar.isDate(previousNow, inSameDayAs: now) {
            Task { await refreshFromCacheAndNetwork() }
        }
    }

    private func loadVisibleDaysFromCache() throws {
        let todayDate = now
        guard let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: todayDate) else {
            return
        }

        let todayMonth = try loadMonth(containing: todayDate)
        let tomorrowMonth = try loadMonth(containing: tomorrowDate)
        today = day(in: todayMonth, matching: todayDate)
        tomorrow = day(in: tomorrowMonth, matching: tomorrowDate)
        updateNextTarget()
    }

    private func loadMonth(containing date: Date) throws -> [PrayerDay] {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return try cache.load(locationSlug: location.slug, year: year, month: month)
    }

    private func day(in days: [PrayerDay], matching date: Date) -> PrayerDay? {
        days.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func updateNextTarget() {
        nextTarget = CountdownEngine.nextTarget(
            now: now,
            days: [today, tomorrow].compactMap { $0 },
            calendar: calendar
        )
    }

    private func fetchMissingOrInvalidVisibleMonths() async throws {
        let visibleDates = [now, calendar.date(byAdding: .day, value: 1, to: now)].compactMap { $0 }
        var requests: [MonthRequest] = []

        for date in visibleDates {
            let request = MonthRequest(
                year: calendar.component(.year, from: date),
                month: calendar.component(.month, from: date)
            )
            if !requests.contains(request) {
                requests.append(request)
            }
        }

        for request in requests {
            let needsFetch: Bool
            if cache.hasMonth(locationSlug: location.slug, year: request.year, month: request.month) {
                needsFetch = (try? cache.load(locationSlug: location.slug, year: request.year, month: request.month)) == nil
            } else {
                needsFetch = true
            }

            guard needsFetch else {
                continue
            }

            let days = try await client.fetchMonth(location: location, year: request.year, month: request.month)
            try cache.save(days: days, locationSlug: location.slug, year: request.year, month: request.month)
        }
    }

    private func handleNotificationPreferenceChange() async {
        if notificationsEnabled {
            do {
                notificationPermissionStatus = "Requesting"
                let granted = try await notificationScheduler.requestAuthorization()
                await updateNotificationPermissionStatus()

                if granted {
                    await rescheduleNotificationsIfNeeded()
                } else {
                    notificationsEnabled = false
                    notificationScheduleStatus = "Permission denied"
                    await notificationScheduler.clearScheduledNotifications()
                }
            } catch {
                notificationPermissionStatus = "Unavailable"
                notificationsEnabled = false
                notificationScheduleStatus = "Unavailable"
                await notificationScheduler.clearScheduledNotifications()
            }
        } else {
            await notificationScheduler.clearScheduledNotifications()
            notificationScheduleStatus = "Disabled"
            await updateNotificationPermissionStatus()
        }
    }

    private func updateNotificationPermissionStatus() async {
        notificationPermissionStatus = await notificationScheduler.permissionStatusText()
    }

    private func rescheduleNotificationsIfNeeded() async {
        guard notificationsEnabled else {
            return
        }

        notificationScheduleStatus = "Scheduling"
        let days = notificationDays(windowDays: 14)
        let entries = NotificationScheduleBuilder.entries(
            now: now,
            days: days,
            reminderOffset: TimeInterval(reminderOffsetMinutes * 60),
            windowDays: 14,
            calendar: calendar
        )

        do {
            try await notificationScheduler.schedule(
                entries: entries,
                calendar: calendar,
                reminderOffsetMinutes: reminderOffsetMinutes
            )
            let count = await notificationScheduler.pendingScheduledCount()
            notificationScheduleStatus = "\(count) scheduled"
        } catch {
            notificationPermissionStatus = "Unavailable"
            notificationScheduleStatus = "Unavailable"
        }

        await updateNotificationPermissionStatus()
    }

    private func notificationDays(windowDays: Int) -> [PrayerDay] {
        let start = calendar.startOfDay(for: now)
        let targetDates = (0...windowDays).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start)
        }
        var requests: [MonthRequest] = []
        for date in targetDates {
            let request = MonthRequest(
                year: calendar.component(.year, from: date),
                month: calendar.component(.month, from: date)
            )
            if !requests.contains(request) {
                requests.append(request)
            }
        }

        var loadedDays: [PrayerDay] = []
        for request in requests {
            let monthDays = try? cache.load(
                locationSlug: location.slug,
                year: request.year,
                month: request.month
            )
            loadedDays.append(contentsOf: monthDays ?? [])
        }

        return targetDates.compactMap { date in
            day(in: loadedDays, matching: date)
        }
    }

    private static func defaultCacheDirectory() -> URL {
        if let appGroupCache = PrayerCache(appGroupIdentifier: "group.com.abdulahproho.vaktija") {
            return appGroupCache.baseDirectory
        }

        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Vaktija", isDirectory: true)
            .appendingPathComponent("PrayerCache", isDirectory: true)
    }
}
