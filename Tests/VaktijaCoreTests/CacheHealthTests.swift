import XCTest
@testable import VaktijaCore

final class CacheHealthTests: XCTestCase {
    func testReportsCachedThroughLastContiguousCachedDay() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = PrayerCache(baseDirectory: directory)
        let calendar = Self.sarajevoCalendar
        let days = (1...31).map { Self.makeDay(year: 2026, month: 5, day: $0, calendar: calendar) }
        try cache.save(days: days, locationSlug: "sarajevo", year: 2026, month: 5)

        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let health = CacheHealth.summary(
            cache: cache,
            locationSlug: "sarajevo",
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(health, "Cached through May 31")
    }

    func testStopsCacheHealthAtMissingMonth() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = PrayerCache(baseDirectory: directory)
        let calendar = Self.sarajevoCalendar
        let days = (1...30).map { Self.makeDay(year: 2026, month: 6, day: $0, calendar: calendar) }
        try cache.save(days: days, locationSlug: "sarajevo", year: 2026, month: 6)

        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let health = CacheHealth.summary(
            cache: cache,
            locationSlug: "sarajevo",
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(health, "No cached times")
    }

    private static var sarajevoCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Sarajevo")!
        return calendar
    }

    private static func makeDay(year: Int, month: Int, day: Int, calendar: Calendar) -> PrayerDay {
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        return PrayerDay(
            date: date,
            locationName: "Sarajevo",
            timeZoneIdentifier: "Europe/Sarajevo",
            times: [
                PrayerTime(event: .fajr, time: time(hour: 3, minute: 20)),
                PrayerTime(event: .sunrise, time: time(hour: 5, minute: 5)),
                PrayerTime(event: .dhuhr, time: time(hour: 12, minute: 45)),
                PrayerTime(event: .asr, time: time(hour: 16, minute: 50)),
                PrayerTime(event: .maghrib, time: time(hour: 20, minute: 20)),
                PrayerTime(event: .isha, time: time(hour: 22, minute: 5))
            ]
        )
    }

    private static func time(hour: Int, minute: Int) -> DateComponents {
        DateComponents(hour: hour, minute: minute)
    }
}
