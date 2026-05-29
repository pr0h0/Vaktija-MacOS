import XCTest
@testable import VaktijaCore

final class NotificationScheduleBuilderTests: XCTestCase {
    func testBuildsReminderAndExactTimeEntries() throws {
        let day = Self.makeDay(asrHour: 16, asrMinute: 45)
        let now = try Self.date("2026-05-29 12:00:00")

        let entries = NotificationScheduleBuilder.entries(
            now: now,
            days: [day],
            reminderOffset: 45 * 60,
            windowDays: 14,
            calendar: Self.calendar
        )

        let asrEntries = entries.filter { $0.event == .asr }
        XCTAssertTrue(asrEntries.contains { $0.kind == .reminder && Self.hourMinute($0.fireDate) == "16:00" })
        XCTAssertTrue(asrEntries.contains { $0.kind == .exact && Self.hourMinute($0.fireDate) == "16:45" })
    }

    func testSkipsPastReminderButKeepsFutureExactTime() throws {
        let day = Self.makeDay(asrHour: 16, asrMinute: 45)
        let now = try Self.date("2026-05-29 16:30:00")

        let entries = NotificationScheduleBuilder.entries(
            now: now,
            days: [day],
            reminderOffset: 45 * 60,
            windowDays: 14,
            calendar: Self.calendar
        )

        let asrEntries = entries.filter { $0.event == .asr }
        XCTAssertFalse(asrEntries.contains { $0.kind == .reminder })
        XCTAssertTrue(asrEntries.contains { $0.kind == .exact && Self.hourMinute($0.fireDate) == "16:45" })
    }

    func testExcludesMidnightAndLastThird() throws {
        let day = Self.makeDay(asrHour: 16, asrMinute: 45)
        let now = try Self.date("2026-05-29 12:00:00")

        let entries = NotificationScheduleBuilder.entries(
            now: now,
            days: [day],
            reminderOffset: 45 * 60,
            windowDays: 14,
            calendar: Self.calendar
        )

        XCTAssertFalse(entries.contains { $0.event == .midnight })
        XCTAssertFalse(entries.contains { $0.event == .lastThird })
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Sarajevo")!
        return calendar
    }

    private static func date(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return try XCTUnwrap(formatter.date(from: value))
    }

    private static func hourMinute(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func makeDay(asrHour: Int, asrMinute: Int) -> PrayerDay {
        var dateComponents = DateComponents()
        dateComponents.calendar = calendar
        dateComponents.timeZone = calendar.timeZone
        dateComponents.year = 2026
        dateComponents.month = 5
        dateComponents.day = 29

        return PrayerDay(
            date: calendar.date(from: dateComponents)!,
            locationName: "Sarajevo",
            timeZoneIdentifier: "Europe/Sarajevo",
            times: [
                PrayerTime(event: .fajr, time: time(hour: 3, minute: 27)),
                PrayerTime(event: .sunrise, time: time(hour: 5, minute: 9)),
                PrayerTime(event: .dhuhr, time: time(hour: 12, minute: 44)),
                PrayerTime(event: .asr, time: time(hour: asrHour, minute: asrMinute)),
                PrayerTime(event: .maghrib, time: time(hour: 20, minute: 19)),
                PrayerTime(event: .isha, time: time(hour: 22, minute: 1)),
                PrayerTime(event: .midnight, time: time(hour: 0, minute: 44)),
                PrayerTime(event: .lastThird, time: time(hour: 2, minute: 12))
            ]
        )
    }

    private static func time(hour: Int, minute: Int) -> DateComponents {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0
        return components
    }
}
