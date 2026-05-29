import Foundation
import UserNotifications
import VaktijaCore

@MainActor
final class NotificationScheduler {
    private let center: UNUserNotificationCenter
    private let identifierPrefix = "vaktija.prayer."

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func permissionStatusText() async -> String {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus.displayTitle
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
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
        calendar: Calendar,
        reminderOffsetMinutes: Int
    ) async throws {
        await clearScheduledNotifications()

        for entry in entries {
            let content = UNMutableNotificationContent()
            content.sound = .default

            switch entry.kind {
            case .reminder:
                content.title = "\(entry.event.rawValue) in \(reminderOffsetMinutes)m"
                content.body = "Starts at \(Self.timeText(for: entry.fireDate.addingTimeInterval(TimeInterval(reminderOffsetMinutes * 60)), calendar: calendar))."
            case .exact:
                content.title = entry.event.rawValue
                content.body = "It is time for \(entry.event.rawValue)."
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
