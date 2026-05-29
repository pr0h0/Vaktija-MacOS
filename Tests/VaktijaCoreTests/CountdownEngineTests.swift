import XCTest
@testable import VaktijaCore

final class CountdownEngineTests: XCTestCase {
    func testNextTargetBeforeSunrise() throws {
        let days = [Self.makeDay(day: 29)]
        let now = try Self.date("2026-05-29 04:00:00")

        let target = try XCTUnwrap(CountdownEngine.nextTarget(now: now, days: days, calendar: Self.calendar))

        XCTAssertEqual(target.event, .sunrise)
        XCTAssertEqual(Self.calendar.component(.hour, from: target.date), 5)
        XCTAssertEqual(Self.calendar.component(.minute, from: target.date), 9)
    }

    func testNextTargetRollsToNextDayFajrAfterIsha() throws {
        let days = [Self.makeDay(day: 29), Self.makeDay(day: 30)]
        let now = try Self.date("2026-05-29 22:30:00")

        let target = try XCTUnwrap(CountdownEngine.nextTarget(now: now, days: days, calendar: Self.calendar))

        XCTAssertEqual(target.event, .fajr)
        XCTAssertEqual(Self.calendar.component(.day, from: target.date), 30)
        XCTAssertEqual(Self.calendar.component(.hour, from: target.date), 3)
        XCTAssertEqual(Self.calendar.component(.minute, from: target.date), 27)
    }

    func testMidnightAndLastThirdAreExcluded() throws {
        let days = [Self.makeDay(day: 29), Self.makeDay(day: 30)]
        let now = try Self.date("2026-05-29 23:00:00")

        let target = try XCTUnwrap(CountdownEngine.nextTarget(now: now, days: days, calendar: Self.calendar))

        XCTAssertNotEqual(target.event, .midnight)
        XCTAssertNotEqual(target.event, .lastThird)
        XCTAssertEqual(target.event, .fajr)
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

    private static func makeDay(day: Int) -> PrayerDay {
        var dateComponents = DateComponents()
        dateComponents.calendar = calendar
        dateComponents.timeZone = calendar.timeZone
        dateComponents.year = 2026
        dateComponents.month = 5
        dateComponents.day = day

        return PrayerDay(
            date: calendar.date(from: dateComponents)!,
            locationName: "Sarajevo",
            timeZoneIdentifier: "Europe/Sarajevo",
            times: [
                PrayerTime(event: .fajr, time: time(hour: 3, minute: 27)),
                PrayerTime(event: .sunrise, time: time(hour: 5, minute: 9)),
                PrayerTime(event: .dhuhr, time: time(hour: 12, minute: 44)),
                PrayerTime(event: .asr, time: time(hour: 16, minute: 48)),
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
