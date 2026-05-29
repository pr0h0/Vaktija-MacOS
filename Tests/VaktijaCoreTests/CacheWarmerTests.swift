import XCTest
@testable import VaktijaCore

final class CacheWarmerTests: XCTestCase {
    func testWarmerFetchesCurrentMonthBeforeRestOfYear() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = PrayerCache(baseDirectory: directory)
        let fetcher = RecordingFetcher()
        let warmer = CacheWarmer(fetcher: fetcher, cache: cache, calendar: Self.calendar)

        try await warmer.warm(location: .sarajevo, now: try Self.date("2026-05-29 12:00:00"))

        XCTAssertEqual(fetcher.requests.first, MonthRequest(year: 2026, month: 5))
        XCTAssertEqual(fetcher.requests.count, 12)
        XCTAssertTrue(fetcher.requests.contains(MonthRequest(year: 2026, month: 1)))
        XCTAssertTrue(fetcher.requests.contains(MonthRequest(year: 2026, month: 12)))
    }

    func testWarmerPrefetchesNextYearInDecember() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = PrayerCache(baseDirectory: directory)
        let fetcher = RecordingFetcher()
        let warmer = CacheWarmer(fetcher: fetcher, cache: cache, calendar: Self.calendar)

        try await warmer.warm(location: .sarajevo, now: try Self.date("2026-12-02 12:00:00"))

        XCTAssertEqual(fetcher.requests.first, MonthRequest(year: 2026, month: 12))
        XCTAssertTrue(fetcher.requests.contains(MonthRequest(year: 2027, month: 1)))
        XCTAssertTrue(fetcher.requests.contains(MonthRequest(year: 2027, month: 12)))
        XCTAssertEqual(fetcher.requests.count, 24)
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
}

private final class RecordingFetcher: PrayerCalendarFetching {
    private(set) var requests: [MonthRequest] = []

    func fetchMonth(location: PrayerLocation, year: Int, month: Int) async throws -> [PrayerDay] {
        requests.append(MonthRequest(year: year, month: month))
        return []
    }
}
