import XCTest
@testable import VaktijaCore

final class CountdownFormatterTests: XCTestCase {
    func testFullCountdownFormat() {
        XCTAssertEqual(CountdownFormatter.full(duration: 43 * 60 + 33), "00:43:33")
        XCTAssertEqual(CountdownFormatter.full(duration: 2 * 60 * 60 + 4), "02:00:04")
    }

    func testCompactCountdownFormat() {
        XCTAssertEqual(CountdownFormatter.compact(event: .asr, duration: 43 * 60 + 33), "Asr 43m")
        XCTAssertEqual(CountdownFormatter.compact(event: .fajr, duration: 65 * 60), "Fajr 1h 05m")
    }
}
