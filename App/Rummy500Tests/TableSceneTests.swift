import XCTest
import RummyEngine
@testable import Rummy500

final class TableSceneTests: XCTestCase {
    func testFreshDealShowsASortedHandAndAFaceDownOpponent() {
        let dealt = HandState.deal(seed: Seed(0))
        let scene = TableScene.load(.freshDeal)

        XCTAssertEqual(scene.preset, .freshDeal)
        XCTAssertEqual(scene.yourHand, TableScene.sortedHand(dealt.you.cards))
        XCTAssertNotEqual(scene.yourHand, dealt.you.cards)
        XCTAssertEqual(scene.yourHand.count, 13)
        XCTAssertEqual(scene.opponentCount, dealt.computer.count)
        XCTAssertEqual(scene.stockCount, dealt.stock.count)
        XCTAssertEqual(scene.discard, dealt.discard.bottomToTop)
        XCTAssertTrue(scene.melds.isEmpty)
        XCTAssertEqual(scene.turnLabel, "Your turn")
        XCTAssertEqual(scene.phaseLabel, "Draw a card")
        XCTAssertEqual(scene.yourScore, 0)
        XCTAssertEqual(scene.computerScore, 0)
        XCTAssertEqual(scene.cardCount, 52)
        XCTAssertFalse(scene.yourHand.contains(dealt.computer.cards[0]))
    }

    func testEachPresetKeepsOneDeckAndHidesTheOpponent() {
        for preset in TablePreset.allCases {
            let scene = TableScene.load(preset)
            let faceUp = scene.yourHand + scene.discard + scene.cards(playedBy: .you) + scene.cards(playedBy: .computer)
            XCTAssertEqual(scene.preset, preset)
            XCTAssertEqual(Set(faceUp).count, faceUp.count)
            XCTAssertEqual(scene.cardCount, 52)
            XCTAssertGreaterThan(scene.opponentCount, 0)
            XCTAssertEqual(scene.yourHand, TableScene.sortedHand(scene.yourHand))
            XCTAssertFalse(scene.turnLabel.isEmpty)
        }
    }

    func testMidHandShowsMeldsLayoffsAndTheComputerTurn() {
        let scene = TableScene.load(.midHand)

        XCTAssertEqual(scene.melds.count, 4)
        XCTAssertEqual(scene.yourHand.count, 4)
        XCTAssertEqual(scene.opponentCount, 9)
        XCTAssertEqual(scene.discard.count, 2)
        XCTAssertEqual(scene.turnLabel, "Computer's turn")
        XCTAssertEqual(scene.phaseLabel, "Meld or discard")
        XCTAssertEqual(scene.yourScore, 20)
        XCTAssertEqual(scene.computerScore, -15)
        let run = scene.melds[0]
        XCTAssertEqual(run.kind, .run)
        XCTAssertEqual(run.laidDownBy, .you)
        XCTAssertEqual(run.cards.last?.card, Card(rank: .four, suit: .diamonds))
        XCTAssertEqual(run.cards.last?.playedBy, .computer)
        let fives = scene.melds[1]
        XCTAssertEqual(fives.kind, .set)
        XCTAssertTrue(fives.cards.contains { entry in
            entry.card == Card(rank: .five, suit: .hearts) && entry.playedBy == .computer
        })
        let mixed = scene.melds.filter { meld in
            Set(meld.cards.map(\.playedBy)).count > 1
        }
        XCTAssertFalse(mixed.isEmpty)
        XCTAssertFalse(scene.cards(playedBy: .you).isEmpty)
        XCTAssertFalse(scene.cards(playedBy: .computer).isEmpty)
        for meld in mixed {
            let yours = meld.cards.filter { $0.playedBy == .you }
            let computers = meld.cards.filter { $0.playedBy == .computer }
            XCTAssertFalse(yours.isEmpty)
            XCTAssertFalse(computers.isEmpty)
        }
    }

    func testLongDiscardLeavesABigHandAndASpreadPile() {
        let scene = TableScene.load(.longDiscard)

        XCTAssertEqual(scene.turnLabel, "Your turn")
        XCTAssertEqual(scene.phaseLabel, "Play the 3 of diamonds")
        XCTAssertEqual(scene.yourHand.count, 21)
        XCTAssertTrue(scene.yourHand.contains(Card(rank: .three, suit: .diamonds)))
        XCTAssertEqual(scene.discard.count, 9)
        XCTAssertFalse(scene.discard.contains(Card(rank: .three, suit: .diamonds)))
        XCTAssertEqual(scene.stockCount, 9)
        XCTAssertEqual(scene.opponentCount, 13)
        XCTAssertTrue(scene.melds.isEmpty)
        XCTAssertEqual(scene.yourScore, 30)
        XCTAssertEqual(scene.computerScore, -25)
        XCTAssertEqual(scene.cardCount, 52)
    }

    func testSuitMarkIsAShapeAsWellAsAColor() {
        XCTAssertEqual(CardLabel.symbol(.clubs), "♣")
        XCTAssertEqual(CardLabel.symbol(.diamonds), "♦")
        XCTAssertEqual(CardLabel.symbol(.hearts), "♥")
        XCTAssertEqual(CardLabel.symbol(.spades), "♠")
        XCTAssertNotEqual(CardLabel.symbol(.hearts), CardLabel.symbol(.diamonds))
        XCTAssertNotEqual(CardLabel.symbol(.clubs), CardLabel.symbol(.spades))
        XCTAssertEqual(CardLabel.letter(.clubs), "C")
        XCTAssertEqual(CardLabel.letter(.diamonds), "D")
        XCTAssertEqual(CardLabel.letter(.hearts), "H")
        XCTAssertEqual(CardLabel.letter(.spades), "S")
        XCTAssertEqual(CardLabel.spoken(Card(rank: .eight, suit: .spades)), "8 of spades")
        XCTAssertTrue(CardLabel.isRed(.hearts))
        XCTAssertTrue(CardLabel.isRed(.diamonds))
        XCTAssertFalse(CardLabel.isRed(.clubs))
        XCTAssertFalse(CardLabel.isRed(.spades))
    }

    func testCardTargetsStayLargeEnoughToSeparateTaps() {
        XCTAssertGreaterThanOrEqual(TableChrome.cardWidth, TableChrome.minimumTap)
        XCTAssertGreaterThanOrEqual(TableChrome.cardHeight, TableChrome.minimumTap)
        XCTAssertGreaterThanOrEqual(TableChrome.handCardWidth, TableChrome.minimumTap)
        XCTAssertGreaterThanOrEqual(TableChrome.handCardHeight, TableChrome.minimumTap)
        XCTAssertGreaterThanOrEqual(TableChrome.discardStride, TableChrome.minimumTap)
        XCTAssertGreaterThanOrEqual(TableChrome.minimumTap, 44)
        XCTAssertGreaterThan(TableChrome.minimumHandReveal, TableChrome.handCardWidth / 2)

        let reveal = TableChrome.handReveal(count: 13, available: 375)
        XCTAssertGreaterThan(reveal, TableChrome.handCardWidth / 2)
        XCTAssertLessThanOrEqual(TableChrome.fanWidth(count: 13, reveal: reveal), 375.5)

        let long = TableChrome.handReveal(count: 21, available: 375)
        XCTAssertGreaterThan(long, TableChrome.handCardWidth / 2)
        XCTAssertGreaterThan(TableChrome.fanWidth(count: 21, reveal: long), 375)
    }
}
