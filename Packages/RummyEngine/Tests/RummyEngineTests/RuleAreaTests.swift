import XCTest
@testable import RummyEngine

final class RuleAreaTests: XCTestCase {
    func testAreasAreTheFiveLaterTickets() {
        let names = Set(RuleArea.allCases.map(\.rawValue))
        XCTAssertEqual(
            names,
            ["cards", "deal", "melds", "turns", "scoring"]
        )
    }
}
