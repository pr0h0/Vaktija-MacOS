import XCTest
@testable import VaktijaCore

final class PrayerScheduleMapperTests: XCTestCase {
    func testMapsSarajevoMay292026AlAdhanDay() throws {
        let data = """
        {
          "code": 200,
          "status": "OK",
          "data": [
            {
              "timings": {
                "Fajr": "03:27 (CEST)",
                "Sunrise": "05:09 (CEST)",
                "Dhuhr": "12:44 (CEST)",
                "Asr": "16:48 (CEST)",
                "Maghrib": "20:19 (CEST)",
                "Isha": "22:01 (CEST)",
                "Midnight": "00:44 (CEST)",
                "Lastthird": "02:12 (CEST)"
              },
              "date": {
                "gregorian": {
                  "date": "29-05-2026",
                  "day": "29",
                  "month": { "number": 5 },
                  "year": "2026"
                }
              },
              "meta": {
                "timezone": "Europe/Sarajevo"
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AlAdhanCalendarResponse.self, from: data)
        let days = try PrayerScheduleMapper.map(
            response: response,
            locationName: "Sarajevo"
        )

        XCTAssertEqual(days.count, 1)
        let day = try XCTUnwrap(days.first)
        XCTAssertEqual(day.locationName, "Sarajevo")
        XCTAssertEqual(day.timeZoneIdentifier, "Europe/Sarajevo")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Sarajevo")!
        XCTAssertEqual(calendar.component(.year, from: day.date), 2026)
        XCTAssertEqual(calendar.component(.month, from: day.date), 5)
        XCTAssertEqual(calendar.component(.day, from: day.date), 29)

        XCTAssertEqual(day.time(for: .fajr)?.hour, 3)
        XCTAssertEqual(day.time(for: .fajr)?.minute, 27)
        XCTAssertEqual(day.time(for: .sunrise)?.hour, 5)
        XCTAssertEqual(day.time(for: .sunrise)?.minute, 9)
        XCTAssertEqual(day.time(for: .dhuhr)?.hour, 12)
        XCTAssertEqual(day.time(for: .dhuhr)?.minute, 44)
        XCTAssertEqual(day.time(for: .asr)?.hour, 16)
        XCTAssertEqual(day.time(for: .asr)?.minute, 48)
        XCTAssertEqual(day.time(for: .maghrib)?.hour, 20)
        XCTAssertEqual(day.time(for: .maghrib)?.minute, 19)
        XCTAssertEqual(day.time(for: .isha)?.hour, 22)
        XCTAssertEqual(day.time(for: .isha)?.minute, 1)
        XCTAssertEqual(day.time(for: .midnight)?.hour, 0)
        XCTAssertEqual(day.time(for: .midnight)?.minute, 44)
        XCTAssertEqual(day.time(for: .lastThird)?.hour, 2)
        XCTAssertEqual(day.time(for: .lastThird)?.minute, 12)
    }
}
