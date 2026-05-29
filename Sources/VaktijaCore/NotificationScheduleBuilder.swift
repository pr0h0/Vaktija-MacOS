import Foundation

public enum NotificationScheduleKind: String, Codable, Equatable, Sendable {
    case reminder
    case exact
}

public struct NotificationScheduleEntry: Codable, Equatable, Sendable {
    public let event: PrayerEvent
    public let kind: NotificationScheduleKind
    public let fireDate: Date

    public init(event: PrayerEvent, kind: NotificationScheduleKind, fireDate: Date) {
        self.event = event
        self.kind = kind
        self.fireDate = fireDate
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
                        fireDate: reminderDate
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
