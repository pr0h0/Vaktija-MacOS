import Foundation

public struct CountdownTarget: Equatable, Sendable {
    public let event: PrayerEvent
    public let date: Date
    public let duration: TimeInterval

    public init(event: PrayerEvent, date: Date, duration: TimeInterval) {
        self.event = event
        self.date = date
        self.duration = duration
    }
}

public enum CountdownEngine {
    public static func nextTarget(
        now: Date,
        days: [PrayerDay],
        calendar: Calendar
    ) -> CountdownTarget? {
        let candidates = days.flatMap { day in
            PrayerEvent.countdownEvents.compactMap { event -> CountdownTarget? in
                guard let time = day.time(for: event),
                      let date = eventDate(day: day, time: time, calendar: calendar),
                      date > now
                else {
                    return nil
                }

                return CountdownTarget(
                    event: event,
                    date: date,
                    duration: date.timeIntervalSince(now)
                )
            }
        }

        return candidates.min { $0.date < $1.date }
    }

    public static func eventDate(
        day: PrayerDay,
        time: DateComponents,
        calendar: Calendar
    ) -> Date? {
        var calendar = calendar
        if let timeZone = TimeZone(identifier: day.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }

        let dayComponents = calendar.dateComponents([.year, .month, .day], from: day.date)

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = dayComponents.year
        components.month = dayComponents.month
        components.day = dayComponents.day
        components.hour = time.hour
        components.minute = time.minute
        components.second = time.second ?? 0

        return calendar.date(from: components)
    }
}
