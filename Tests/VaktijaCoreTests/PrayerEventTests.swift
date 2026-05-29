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
}
