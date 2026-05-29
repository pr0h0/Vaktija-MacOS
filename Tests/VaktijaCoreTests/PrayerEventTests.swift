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
}
