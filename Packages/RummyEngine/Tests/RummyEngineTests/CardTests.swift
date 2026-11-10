import XCTest
@testable import RummyEngine

final class CardTests: XCTestCase {
    func testPointValuesFollowTheSheet() {
        let expected: [Rank: Int] = [
            .ace: 15,
            .two: 2,
            .three: 3,
            .four: 4,
            .five: 5,
            .six: 6,
            .seven: 7,
            .eight: 8,
            .nine: 9,
            .ten: 10,
            .jack: 10,
            .queen: 10,
            .king: 10,
        ]
        XCTAssertEqual(Set(Rank.allCases), Set(expected.keys))
        for rank in Rank.allCases {
            XCTAssertEqual(rank.points, expected[rank])
            XCTAssertEqual(Card(rank: rank, suit: .hearts).points, expected[rank])
        }
    }
}
