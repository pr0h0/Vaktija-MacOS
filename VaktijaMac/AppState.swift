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
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }
    @Published var reminderOffsetMinutes: Int {
        didSet { defaults.set(reminderOffsetMinutes, forKey: Keys.reminderOffsetMinutes) }
    }
    @Published var notificationPermissionStatus = "Not Requested"
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
        self.menuBarDisplayMode = rawMode.flatMap(MenuBarDisplayMode.init(rawValue:)) ?? .iconOnly
        self.notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled)
        let storedOffset = defaults.integer(forKey: Keys.reminderOffsetMinutes)
        self.reminderOffsetMinutes = storedOffset == 0 ? 45 : storedOffset

        startTimer()
        Task { await refreshFromCacheAndNetwork() }
    }

    func refreshFromCacheAndNetwork() async {
        do {
            try loadVisibleDaysFromCache()
            cacheStatus = "Cached"
        } catch {
            cacheStatus = "Fetching"
        }

        do {
            let year = calendar.component(.year, from: now)
            let month = calendar.component(.month, from: now)

            if !cache.hasMonth(locationSlug: location.slug, year: year, month: month) {
                let days = try await client.fetchMonth(location: location, year: year, month: month)
                try cache.save(days: days, locationSlug: location.slug, year: year, month: month)
            }

            try loadVisibleDaysFromCache()
            cacheStatus = "Updated"

            Task.detached { [cache, client, location] in
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(identifier: location.timeZoneIdentifier) ?? .current
                let warmer = CacheWarmer(fetcher: client, cache: cache, calendar: calendar)
                try? await warmer.warm(location: location, now: Date())
            }
        } catch {
            cacheStatus = today == nil ? "Unavailable" : "Offline Cache"
        }
    }

    func displayTime(_ components: DateComponents?) -> String {
        guard let hour = components?.hour, let minute = components?.minute else {
            return "--:--"
        }
        return String(format: "%02d:%02d", hour, minute)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func tick() {
        now = Date()
        updateNextTarget()
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

    private static func defaultCacheDirectory() -> URL {
        if let appGroupCache = PrayerCache(appGroupIdentifier: "group.com.abdulahproho.vaktija") {
            return appGroupCache.baseDirectory
        }

        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Vaktija", isDirectory: true)
            .appendingPathComponent("PrayerCache", isDirectory: true)
    }
}
