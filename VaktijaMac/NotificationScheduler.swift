import Foundation
import AppKit
import UserNotifications
import VaktijaCore

@MainActor
final class NotificationScheduler {
    private let center: UNUserNotificationCenter
    private let presentationDelegate = NotificationPresentationDelegate()
    private let identifierPrefix = "vaktija.prayer."

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        self.center.delegate = presentationDelegate
    }

    func permissionStatusText() async -> String {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus.displayTitle
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func pendingScheduledCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.filter { $0.identifier.hasPrefix(identifierPrefix) }.count
    }

    func openNotificationSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.Notifications-Settings.extension",
            "x-apple.systempreferences:com.apple.preference.notifications"
        ]

        for rawURL in urls {
            guard let url = URL(string: rawURL), NSWorkspace.shared.open(url) else {
                continue
            }
            return
        }
    }

    func clearScheduledNotifications() async {
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }

        guard !identifiers.isEmpty else {
            return
        }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func schedule(
        entries: [NotificationScheduleEntry],
        calendar: Calendar
    ) async throws {
        await clearScheduledNotifications()

        for entry in entries {
            let content = UNMutableNotificationContent()
            content.sound = .default

            switch entry.kind {
            case .reminder:
                let offset = entry.reminderOffsetMinutes ?? 0
                let prayerName = entry.event.displayName(on: entry.fireDate, calendar: calendar)
                content.title = "\(prayerName) in \(offset)m"
                content.body = "Starts at \(Self.timeText(for: entry.fireDate.addingTimeInterval(TimeInterval(offset * 60)), calendar: calendar))."
            case .exact:
                let prayerName = entry.event.displayName(on: entry.fireDate, calendar: calendar)
                content.title = prayerName
                content.body = "It is time for \(prayerName)."
            }

            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: entry.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifier(for: entry),
                content: content,
                trigger: trigger
            )

            try await center.add(request)
        }
    }

    func scheduleTestNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Vaktija Test"
        content.body = "Notifications are working."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(identifierPrefix)test.\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    private func identifier(for entry: NotificationScheduleEntry) -> String {
        let timestamp = Int(entry.fireDate.timeIntervalSince1970)
        return "\(identifierPrefix)\(entry.kind.rawValue).\(entry.event.identifierComponent).\(timestamp)"
    }

    private static func timeText(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}

private extension UNAuthorizationStatus {
    var displayTitle: String {
        switch self {
        case .notDetermined:
            "Not Requested"
        case .denied:
            "Denied"
        case .authorized:
            "Authorized"
        case .provisional:
            "Provisional"
        case .ephemeral:
            "Ephemeral"
        @unknown default:
            "Unknown"
        }
    }
}

private extension PrayerEvent {
    var identifierComponent: String {
        switch self {
        case .fajr: "fajr"
        case .sunrise: "sunrise"
        case .dhuhr: "dhuhr"
        case .asr: "asr"
        case .maghrib: "maghrib"
        case .isha: "isha"
        case .midnight: "midnight"
        case .lastThird: "last-third"
        }
    }
}

private final class NotificationPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
