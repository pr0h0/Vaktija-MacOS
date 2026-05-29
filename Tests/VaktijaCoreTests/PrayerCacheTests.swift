import XCTest
@testable import VaktijaCore

final class PrayerCacheTests: XCTestCase {
    func testSavesAndLoadsMonthlyPrayerDays() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = PrayerCache(baseDirectory: directory)
        let days = [Self.makeDay(day: 29)]

        try cache.save(days: days, locationSlug: "sarajevo", year: 2026, month: 5)
        let loaded = try cache.load(locationSlug: "sarajevo", year: 2026, month: 5)

        XCTAssertEqual(loaded, days)
    }

    private static func makeDay(day: Int) -> PrayerDay {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Sarajevo")!

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
