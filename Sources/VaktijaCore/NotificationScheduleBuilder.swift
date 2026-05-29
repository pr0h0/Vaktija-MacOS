import Foundation

public enum NotificationScheduleKind: String, Codable, Equatable, Sendable {
    case reminder
    case exact
}

public struct NotificationScheduleEntry: Codable, Equatable, Sendable {
    public let event: PrayerEvent
    public let kind: NotificationScheduleKind
    public let fireDate: Date
    public let reminderOffsetMinutes: Int?

    public init(
        event: PrayerEvent,
        kind: NotificationScheduleKind,
        fireDate: Date,
        reminderOffsetMinutes: Int? = nil
    ) {
        self.event = event
        self.kind = kind
        self.fireDate = fireDate
        self.reminderOffsetMinutes = reminderOffsetMinutes
    }
}

public struct PrayerNotificationPreference: Codable, Equatable, Identifiable, Sendable {
    public let event: PrayerEvent
    public var isEnabled: Bool
    public var reminderOffsetMinutes: Int

    public var id: PrayerEvent { event }

    public init(event: PrayerEvent, isEnabled: Bool, reminderOffsetMinutes: Int) {
        self.event = event
        self.isEnabled = isEnabled
        self.reminderOffsetMinutes = reminderOffsetMinutes
    }
}

public enum NotificationScheduleBuilder {
    public static func entries(
        now: Date,
        days: [PrayerDay],
        reminderOffset: TimeInterval,
        windowDays: Int = 14,
        calendar: Calendar
    ) -> [NotificationScheduleEntry] {
        let windowEnd = calendar.date(byAdding: .day, value: windowDays, to: now) ?? now

        let entries = days.flatMap { day in
            PrayerEvent.countdownEvents.flatMap { event -> [NotificationScheduleEntry] in
                guard let time = day.time(for: event),
                      let eventDate = CountdownEngine.eventDate(day: day, time: time, calendar: calendar),
                      eventDate <= windowEnd
                else {
                    return []
                }

                let reminderDate = eventDate.addingTimeInterval(-reminderOffset)
                var eventEntries: [NotificationScheduleEntry] = []

                if reminderDate > now {
                    eventEntries.append(NotificationScheduleEntry(
                        event: event,
                        kind: .reminder,
                        fireDate: reminderDate,
                        reminderOffsetMinutes: Int(reminderOffset / 60)
                    ))
                }

                if eventDate > now {
                    eventEntries.append(NotificationScheduleEntry(
                        event: event,
                        kind: .exact,
                        fireDate: eventDate
                    ))
                }

                return eventEntries
            }
        }

        return entries.sorted { $0.fireDate < $1.fireDate }
    }

    public static func entries(
        now: Date,
        days: [PrayerDay],
        preferences: [PrayerNotificationPreference],
        windowDays: Int = 14,
        calendar: Calendar
    ) -> [NotificationScheduleEntry] {
        let enabledPreferences = preferences.reduce(into: [PrayerEvent: PrayerNotificationPreference]()) { result, preference in
            guard preference.isEnabled, PrayerEvent.countdownEvents.contains(preference.event) else {
                return
            }

            result[preference.event] = preference
        }
        let windowEnd = calendar.date(byAdding: .day, value: windowDays, to: now) ?? now

        let entries = days.flatMap { day in
            PrayerEvent.countdownEvents.flatMap { event -> [NotificationScheduleEntry] in
                guard let preference = enabledPreferences[event],
                      let time = day.time(for: event),
                      let eventDate = CountdownEngine.eventDate(day: day, time: time, calendar: calendar),
                      eventDate <= windowEnd
                else {
                    return []
                }

                let offset = TimeInterval(preference.reminderOffsetMinutes * 60)
                let reminderDate = eventDate.addingTimeInterval(-offset)
                var eventEntries: [NotificationScheduleEntry] = []

                if reminderDate > now {
                    eventEntries.append(NotificationScheduleEntry(
                        event: event,
                        kind: .reminder,
                        fireDate: reminderDate,
                        reminderOffsetMinutes: preference.reminderOffsetMinutes
                    ))
                }

                if eventDate > now {
                    eventEntries.append(NotificationScheduleEntry(
                        event: event,
                        kind: .exact,
                        fireDate: eventDate
                    ))
                }

                return eventEntries
            }
        }

        return entries.sorted { $0.fireDate < $1.fireDate }
    }
}
