import XCTest
@testable import RummyEngine

final class ScoreTests: XCTestCase {
    func testTableCardsScoreTheirPointValues() {
        let result = HandResult(
            you: .init(table: [
                Card(rank: .king, suit: .hearts),
                Card(rank: .seven, suit: .hearts),
            ]),
            computer: .init(table: [
                Card(rank: .ten, suit: .clubs),
            ])
        )
        XCTAssertEqual(result.score.you, 17)
        XCTAssertEqual(result.score.computer, 10)
    }

    func testALowAceInARunStillScoresFifteen() {
        let result = HandResult(
            you: .init(table: [
                Card(rank: .ace, suit: .hearts),
                Card(rank: .two, suit: .hearts),
                Card(rank: .three, suit: .hearts),
            ])
        )
        XCTAssertEqual(result.score.you, 20)
        XCTAssertEqual(result.score.computer, 0)
    }

    func testCardsLeftInHandMakeTheScoreNegative() {
        let result = HandResult(
            you: .init(
                table: [Card(rank: .five, suit: .hearts)],
                hand: [Card(rank: .ace, suit: .clubs)]
            )
        )
        XCTAssertEqual(result.score.you, -10)
        let match = Match.opening.record(result)
        XCTAssertEqual(match.you, -10)
        XCTAssertEqual(match.computer, 0)
        XCTAssertEqual(match.conclusion, .playing)
        XCTAssertEqual(match.hands, [result.score])
    }

    func testAnUnmeldedAceCostsFifteen() {
        let result = HandResult(
            you: .init(hand: [Card(rank: .ace, suit: .spades)])
        )
        XCTAssertEqual(result.score.you, -15)
    }

    func testALaidOffCardCountsForThePlayerWhoPlayedIt() {
        let result = HandResult(
            you: .init(table: [
                Card(rank: .four, suit: .hearts),
                Card(rank: .five, suit: .hearts),
                Card(rank: .six, suit: .hearts),
                Card(rank: .seven, suit: .hearts),
            ]),
            computer: .init(table: [
                Card(rank: .four, suit: .spades),
                Card(rank: .five, suit: .spades),
                Card(rank: .six, suit: .spades),
            ])
        )
        XCTAssertEqual(result.score.you, 22)
        XCTAssertEqual(result.score.computer, 15)
    }

    func testTheSamePointValuesApplyToCardsLeftInHand() {
        let result = HandResult(
            you: .init(
                table: [Card(rank: .king, suit: .hearts)],
                hand: [Card(rank: .king, suit: .spades)]
            )
        )
        XCTAssertEqual(result.score.you, 0)
    }

    func testCrossingFiveHundredMidMatchNamesTheLeader() {
        let before = play([
            HandPoints(youTable: 200),
            HandPoints(youTable: 200, computerTable: 40),
        ])
        XCTAssertEqual(before.you, 400)
        XCTAssertEqual(before.computer, 40)
        XCTAssertEqual(before.conclusion, .playing)
        XCTAssertEqual(before.hands.count, 2)

        let after = play([
            HandPoints(youTable: 200),
            HandPoints(youTable: 200, computerTable: 40),
            HandPoints(youTable: 150, computerTable: 20),
        ])
        XCTAssertEqual(after.you, 550)
        XCTAssertEqual(after.computer, 60)
        XCTAssertEqual(after.conclusion, .won(.you))
        XCTAssertEqual(after.hands.map(\.you), [200, 200, 150])
        XCTAssertEqual(after.hands.map(\.computer), [0, 40, 20])
    }

    func testBothPlayersOverFiveHundredAndTheHigherTotalWins() {
        let before = play([
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 180, computerTable: 180),
        ])
        XCTAssertEqual(before.you, 360)
        XCTAssertEqual(before.computer, 360)
        XCTAssertEqual(before.conclusion, .playing)

        let after = play([
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 180, computerTable: 150),
        ])
        XCTAssertEqual(after.you, 540)
        XCTAssertEqual(after.computer, 510)
        XCTAssertEqual(after.conclusion, .won(.you))
    }

    func testTheComputerWinsByReachingFiveHundredAlone() {
        let match = play([
            HandPoints(computerTable: 200),
            HandPoints(computerTable: 200),
            HandPoints(youTable: 40, computerTable: 150),
        ])
        XCTAssertEqual(match.you, 40)
        XCTAssertEqual(match.computer, 550)
        XCTAssertEqual(match.conclusion, .won(.computer))
    }

    func testAnExactTieAtFiveHundredForcesAnotherHand() {
        let tied = play([
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 140, computerTable: 140),
        ])
        XCTAssertEqual(tied.you, 500)
        XCTAssertEqual(tied.computer, 500)
        XCTAssertEqual(tied.conclusion, .playing)
        XCTAssertEqual(tied.hands.count, 3)

        let decided = play([
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 140, computerTable: 140),
            HandPoints(youTable: 30, computerTable: 10),
        ])
        XCTAssertEqual(decided.you, 530)
        XCTAssertEqual(decided.computer, 510)
        XCTAssertEqual(decided.conclusion, .won(.you))
    }

    func testATiedDecidingHandStillDoesNotNameAWinner() {
        let stillTied = play([
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 140, computerTable: 140),
            HandPoints(),
        ])
        XCTAssertEqual(stillTied.you, 500)
        XCTAssertEqual(stillTied.computer, 500)
        XCTAssertEqual(stillTied.conclusion, .playing)

        let decided = play([
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 140, computerTable: 140),
            HandPoints(),
            HandPoints(computerTable: 10),
        ])
        XCTAssertEqual(decided.you, 500)
        XCTAssertEqual(decided.computer, 510)
        XCTAssertEqual(decided.conclusion, .won(.computer))
    }

    func testTheHigherTotalWinsWhenTheDecidingHandDropsBelowFiveHundred() {
        let decided = play([
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 180, computerTable: 180),
            HandPoints(youTable: 140, computerTable: 140),
            HandPoints(youHand: 50, computerHand: 20),
        ])
        XCTAssertEqual(decided.you, 450)
        XCTAssertEqual(decided.computer, 480)
        XCTAssertEqual(decided.conclusion, .won(.computer))
    }

    private func play(_ hands: [HandPoints]) -> Match {
        var match = Match.opening
        for hand in hands {
            var supply = CardSupply()
            let result = supply.result(hand)
            XCTAssertEqual(result.score.you, hand.youTable - hand.youHand)
            XCTAssertEqual(result.score.computer, hand.computerTable - hand.computerHand)
            match = match.record(result)
        }
        return match
    }
}

private struct HandPoints {
    var youTable = 0
    var youHand = 0
    var computerTable = 0
    var computerHand = 0
}

private struct CardSupply {
    private var remaining: [Card]

    init() {
        remaining = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                remaining.append(Card(rank: rank, suit: suit))
            }
        }
    }

    mutating func result(_ points: HandPoints) -> HandResult {
        HandResult(
            you: .init(
                table: take(points: points.youTable),
                hand: take(points: points.youHand)
            ),
            computer: .init(
                table: take(points: points.computerTable),
                hand: take(points: points.computerHand)
            )
        )
    }

    private mutating func take(points target: Int) -> [Card] {
        precondition(target >= 0)
        var left = target
        var taken: [Card] = []
        let ordered = remaining.sorted { $0.points > $1.points }
        for card in ordered where card.points <= left {
            taken.append(card)
            left -= card.points
        }
        precondition(left == 0, "No set of cards sums to \(target)")
        let used = Set(taken)
        remaining.removeAll { used.contains($0) }
        return taken
    }
}
