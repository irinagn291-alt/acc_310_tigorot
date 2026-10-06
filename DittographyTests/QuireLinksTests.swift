import XCTest
@testable import Dittography

final class QuireLinksTests: XCTestCase {
    func test_reviewScreenKeys_openThreeDifferentScreens() {
        XCTAssertEqual(QuireLinks.route(fromArguments: ["-ReviewScreen", "today"]), .quiz)
        XCTAssertEqual(QuireLinks.route(fromArguments: ["-ReviewScreen", "log"]), .saved)
        XCTAssertEqual(QuireLinks.route(fromArguments: ["-ReviewScreen", "goals"]), .settings)
        XCTAssertEqual(QuireLinks.route(fromArguments: ["-ReviewScreen", "explore"]), .explore)
        XCTAssertNotEqual(
            QuireLinks.route(fromKey: "today"),
            QuireLinks.route(fromKey: "log")
        )
        XCTAssertNotEqual(
            QuireLinks.route(fromKey: "log"),
            QuireLinks.route(fromKey: "goals")
        )
        XCTAssertNotEqual(
            QuireLinks.route(fromKey: "today"),
            QuireLinks.route(fromKey: "goals")
        )
        XCTAssertNil(QuireLinks.route(fromArguments: ["-ReviewScreen"]))
        XCTAssertNil(QuireLinks.route(fromKey: "unknown"))
    }

    func test_dittographyURLs_mapToJobs() {
        XCTAssertEqual(QuireLinks.route(from: URL(string: "dittography://quiz") ?? URL(fileURLWithPath: "/")), .quiz)
        XCTAssertEqual(QuireLinks.route(from: URL(string: "https://dittography-quire.pro/explore") ?? URL(fileURLWithPath: "/")), .explore)
        XCTAssertEqual(QuireLinks.route(from: URL(string: "https://dittography-quire.pro/saved") ?? URL(fileURLWithPath: "/")), .saved)
        XCTAssertEqual(QuireLinks.route(from: URL(string: "dittography://settings") ?? URL(fileURLWithPath: "/")), .settings)
    }
}
