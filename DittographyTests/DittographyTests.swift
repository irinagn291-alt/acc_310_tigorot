import XCTest
@testable import Dittography

final class DittographyTests: XCTestCase {
    func test_dayKey_usesStartOfDayComponents() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 9
        parts.day = 21
        let date = try XCTUnwrap(calendar.date(from: parts))
        XCTAssertEqual(DayKey.from(date, calendar: calendar), 2_026_092_1)
    }
}
