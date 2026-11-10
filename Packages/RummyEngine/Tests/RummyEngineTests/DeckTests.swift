import XCTest
@testable import RummyEngine

final class DeckTests: XCTestCase {
    func testStandardDeckIsThe52RankAndSuitPairs() {
        let expected = Set(Suit.allCases.flatMap { suit in
            Rank.allCases.map { Card(rank: $0, suit: suit) }
        })
        XCTAssertEqual(Deck.standard.topToBottom.count, 52)
        XCTAssertEqual(Set(Deck.standard.topToBottom), expected)
    }

    func testShuffleKeepsEveryCard() {
        var generator = SeededGenerator(seed: Seed(1))
        let shuffled = Deck.standard.shuffled(using: &generator)
        XCTAssertEqual(shuffled.topToBottom.count, 52)
        XCTAssertEqual(Set(shuffled.topToBottom), Set(Deck.standard.topToBottom))
    }

    func testSameSeedShufflesTheSameWay() {
        var first = SeededGenerator(seed: Seed(4))
        var second = SeededGenerator(seed: Seed(4))
        XCTAssertEqual(
            Deck.standard.shuffled(using: &first),
            Deck.standard.shuffled(using: &second)
        )
    }

    func testDifferentSeedsShuffleDifferently() {
        var first = SeededGenerator(seed: Seed(4))
        var second = SeededGenerator(seed: Seed(5))
        XCTAssertNotEqual(
            Deck.standard.shuffled(using: &first),
            Deck.standard.shuffled(using: &second)
        )
    }
}
