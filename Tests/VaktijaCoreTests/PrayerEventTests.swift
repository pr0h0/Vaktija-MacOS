import XCTest
@testable import VaktijaCore

final class PrayerEventTests: XCTestCase {
    func testCountdownEventsIncludeSunriseAndExcludeNightInfo() {
        XCTAssertEqual(
            PrayerEvent.countdownEvents,
            [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]
        )
        XCTAssertFalse(PrayerEvent.countdownEvents.contains(.midnight))
        XCTAssertFalse(PrayerEvent.countdownEvents.contains(.lastThird))
    }

    func testBosnianDisplayNamesForPrayerTimes() {
        XCTAssertEqual(PrayerEvent.fajr.displayName, "Sabah")
        XCTAssertEqual(PrayerEvent.sunrise.displayName, "Izlazak")
        XCTAssertEqual(PrayerEvent.dhuhr.displayName, "Podne")
        XCTAssertEqual(PrayerEvent.asr.displayName, "Ikindija")
        XCTAssertEqual(PrayerEvent.maghrib.displayName, "Akšam")
        XCTAssertEqual(PrayerEvent.isha.displayName, "Jacija")
        XCTAssertEqual(PrayerEvent.midnight.displayName, "Pola noći")
        XCTAssertEqual(PrayerEvent.lastThird.displayName, "Zadnja trećina")
    }

    func testDisplayNameUsesDzumaForDhuhrOnFriday() throws {
        let calendar = Self.sarajevoCalendar
        let friday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let thursday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 28)))

        XCTAssertEqual(PrayerEvent.dhuhr.displayName(on: friday, calendar: calendar), "Džuma")
        XCTAssertEqual(PrayerEvent.dhuhr.displayName(on: thursday, calendar: calendar), "Podne")
        XCTAssertEqual(PrayerEvent.asr.displayName(on: friday, calendar: calendar), "Ikindija")
    }

    private static var sarajevoCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Sarajevo")!
        return calendar
    }
}
