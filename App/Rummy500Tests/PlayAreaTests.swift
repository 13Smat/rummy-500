import CoreGraphics
import XCTest
import RummyEngine
@testable import Rummy500

final class PlayAreaTests: XCTestCase {
    private let seven = Card(rank: .seven, suit: .hearts)
    private let eight = Card(rank: .eight, suit: .hearts)
    private let nine = Card(rank: .nine, suit: .hearts)
    private let twoClubs = Card(rank: .two, suit: .clubs)
    private let fourClubs = Card(rank: .four, suit: .clubs)
    private let twoDiamonds = Card(rank: .two, suit: .diamonds)

    func testStageRemoveAndClear() {
        let ready = readyToMeld()
        XCTAssertFalse(ready.playIsEnabled)
        XCTAssertTrue(ready.playArea.cards.isEmpty)

        let one = ready.stage(seven)
        XCTAssertEqual(one.playArea.cards, [seven])
        XCTAssertFalse(one.order.contains(seven))
        XCTAssertFalse(one.playIsEnabled)

        let two = one.stage(eight)
        XCTAssertEqual(two.playArea.cards, [seven, eight])
        XCTAssertFalse(two.playIsEnabled)

        let again = two.stage(seven)
        XCTAssertEqual(again.playArea.cards, two.playArea.cards)
        XCTAssertEqual(again.order, two.order)

        let removed = two.unstage(eight)
        XCTAssertEqual(removed.playArea.cards, [seven])
        XCTAssertEqual(removed.order.last, eight)
        XCTAssertFalse(removed.order.dropLast().contains(eight))
        XCTAssertFalse(removed.playIsEnabled)

        let cleared = two.clearPlayArea()
        XCTAssertTrue(cleared.playArea.cards.isEmpty)
        XCTAssertEqual(Set(cleared.order), Set(ready.order))
        XCTAssertEqual(cleared.order.count, ready.order.count)
        XCTAssertFalse(cleared.playIsEnabled)
        XCTAssertEqual(cleared.clearPlayArea().order, cleared.order)
    }

    func testThreeHeartsEnablePlayAndTwoDoNot() {
        let ready = readyToMeld()
        let two = ready.stage(seven).stage(eight)
        XCTAssertEqual(two.playArea.offer(in: two.hand), .notReady)
        XCTAssertFalse(two.playIsEnabled)

        let mixed = ready.stage(twoClubs).stage(fourClubs).stage(twoDiamonds)
        XCTAssertEqual(mixed.playArea.offer(in: mixed.hand), .notReady)
        XCTAssertFalse(mixed.playIsEnabled)
        XCTAssertEqual(mixed.playStaged().hand, mixed.hand)
        XCTAssertFalse(mixed.playStaged().notice?.isEmpty ?? true)

        let three = two.stage(nine)
        XCTAssertEqual(three.playArea.offer(in: three.hand), .layDown)
        XCTAssertTrue(three.playIsEnabled)

        let played = three.playStaged()
        XCTAssertNil(played.notice)
        XCTAssertTrue(played.playArea.cards.isEmpty)
        XCTAssertEqual(played.hand.melds.count, 1)
        XCTAssertEqual(played.hand.melds[0].kind, .run)
        XCTAssertEqual(
            played.hand.melds[0].cards,
            [seven, eight, nine]
        )
        XCTAssertFalse(played.order.contains(seven))
        XCTAssertFalse(played.hand.you.cards.contains(seven))
        XCTAssertEqual(played.scene.yourScore, played.match.you)
        XCTAssertEqual(played.match.you, ready.match.you)
        XCTAssertNil(played.hand.handResult)
    }

    func testAHeartThreeLaysOffOnTheOnlyMatchingMeld() {
        let owed = Card(rank: .three, suit: .hearts)
        let holding = TableSession(hand: HandState.scriptedPlay()[7], match: .opening, playsLive: false)
        XCTAssertEqual(holding.owedCard, owed)
        XCTAssertFalse(holding.playIsEnabled)

        let leftOut = holding.stage(twoClubs)
        XCTAssertEqual(leftOut.playArea.offer(in: leftOut.hand), .needsPickedCard)
        XCTAssertFalse(leftOut.playIsEnabled)
        XCTAssertEqual(leftOut.playRefusal, "Include the card you took from the discard.")
        XCTAssertEqual(leftOut.playStaged().notice, "Include the card you took from the discard.")
        XCTAssertEqual(leftOut.playStaged().hand, leftOut.hand)

        let staged = holding.stage(owed)
        XCTAssertEqual(staged.playArea.offer(in: staged.hand), .layOff(1))
        XCTAssertTrue(staged.playIsEnabled)
        XCTAssertNil(staged.playRefusal)

        let played = staged.playStaged()
        XCTAssertNil(played.notice)
        XCTAssertNil(played.owedCard)
        XCTAssertTrue(played.playArea.cards.isEmpty)
        XCTAssertEqual(played.hand, HandState.scriptedPlay()[8])
        XCTAssertFalse(played.order.contains(owed))
        XCTAssertEqual(played.scene.yourScore, holding.scene.yourScore)
    }

    func testADragStagesAndAReturnDragUnstages() {
        let layout = TableLayout(
            zones: [
                .playArea: CGRect(x: 0, y: 0, width: 200, height: 80),
                .hand: CGRect(x: 0, y: 200, width: 200, height: 80),
                .discard: CGRect(x: 220, y: 0, width: 80, height: 80),
            ],
            handSlots: [
                HandSlot(index: 0, card: .hand(seven), frame: CGRect(x: 0, y: 200, width: 48, height: 68)),
                HandSlot(index: 2, card: .hand(nine), frame: CGRect(x: 120, y: 200, width: 48, height: 68)),
            ]
        )
        let dragged = DraggedCard.hand(seven)
        XCTAssertEqual(
            CardDragRoute.drop(dragged, at: CGPoint(x: 40, y: 40), in: layout),
            .stage(dragged)
        )
        XCTAssertEqual(
            CardDragRoute.drop(dragged, at: CGPoint(x: 40, y: 90), in: layout),
            .stage(dragged)
        )
        XCTAssertEqual(
            CardDragRoute.drop(dragged, at: CGPoint(x: 144, y: 234), in: layout),
            .placeInHand(dragged, at: 2)
        )
        XCTAssertEqual(
            CardDragRoute.drop(dragged, at: CGPoint(x: 230, y: 40), in: layout),
            .discard(dragged)
        )
        XCTAssertNil(CardDragRoute.drop(dragged, at: CGPoint(x: 40, y: 140), in: layout))

        let ready = readyToMeld()
        let staged = ready.receive(.stage(.hand(seven)))
        XCTAssertEqual(staged.playArea.cards, [seven])
        let back = staged.receive(.placeInHand(.playArea(seven), at: staged.order.count))
        XCTAssertTrue(back.playArea.cards.isEmpty)
        XCTAssertEqual(back.order.last, seven)
        XCTAssertEqual(staged.receive(.placeInHand(.hand(twoClubs), at: 0)).playArea.cards, [seven])
    }

    func testFiveThenSixAndJackThenTenExtendTheDiamondRun() {
        let five = Card(rank: .five, suit: .diamonds)
        let six = Card(rank: .six, suit: .diamonds)
        let seven = Card(rank: .seven, suit: .diamonds)
        let eight = Card(rank: .eight, suit: .diamonds)
        let nine = Card(rank: .nine, suit: .diamonds)
        let ten = Card(rank: .ten, suit: .diamonds)
        let jack = Card(rank: .jack, suit: .diamonds)
        let drawn = TableSession.opening(seed: 8029, playsLive: false).drawFromStock()
        let laid = drawn.stage(seven).stage(eight).stage(nine).playStaged()
        XCTAssertNil(laid.notice)
        XCTAssertEqual(laid.hand.melds.map(\.cards), [[seven, eight, nine]])

        let lowFirst = laid.stage(five).stage(six)
        XCTAssertTrue(lowFirst.playIsEnabled)
        let low = lowFirst.playStaged()
        XCTAssertNil(low.notice)
        XCTAssertEqual(low.hand.melds[0].cards, [five, six, seven, eight, nine])

        let lowReverse = laid.stage(six).stage(five).playStaged()
        XCTAssertEqual(lowReverse.hand.melds[0].cards, [five, six, seven, eight, nine])
        XCTAssertFalse(laid.stage(five).playIsEnabled)

        let high = laid.stage(jack).stage(ten).playStaged()
        XCTAssertNil(high.notice)
        XCTAssertEqual(high.hand.melds[0].cards, [seven, eight, nine, ten, jack])

        let highReverse = laid.stage(ten).stage(jack).playStaged()
        XCTAssertEqual(highReverse.hand.melds[0].cards, [seven, eight, nine, ten, jack])
    }

    func testPlayStaysOffUntilYouHaveDrawn() {
        let dealt = TableSession(hand: HandState.scriptedPlay()[0], match: .opening, playsLive: false)
        let staged = dealt.stage(seven).stage(eight).stage(nine)
        XCTAssertFalse(staged.playIsEnabled)
        let refused = staged.playStaged()
        XCTAssertEqual(refused.notice, "Draw a card before you play.")
        XCTAssertEqual(refused.hand, staged.hand)
        XCTAssertEqual(refused.playArea.cards, staged.playArea.cards)
    }

    func testTheComputerTurnRefusesAStage() {
        let waiting = TableSession(preset: .midHand, playsLive: false)
        let card = waiting.order[0]
        let blocked = waiting.stage(card)
        XCTAssertEqual(blocked.notice, "Wait for the computer.")
        XCTAssertTrue(blocked.playArea.cards.isEmpty)
        XCTAssertEqual(blocked.order, waiting.order)
        XCTAssertFalse(blocked.playIsEnabled)
    }

    func testTheOnlyStagedCardCanBeDiscarded() {
        let ready = readyToMeld()
        let staged = ready.stage(twoClubs)
        let discarded = staged.receive(.discard(.playArea(twoClubs)))
        XCTAssertNil(discarded.notice)
        XCTAssertTrue(discarded.playArea.cards.isEmpty)
        XCTAssertFalse(discarded.hand.you.cards.contains(twoClubs))
        XCTAssertEqual(discarded.hand.turn, .computer)

        let pair = ready.stage(seven).stage(eight)
        let refused = pair.receive(.discard(.playArea(seven)))
        XCTAssertEqual(refused.notice, "Discard one card.")
        XCTAssertEqual(refused.hand, pair.hand)
        XCTAssertEqual(refused.playArea.cards, [seven, eight])
    }

    func testADiscardKeepsTheStagedCards() {
        let ready = readyToMeld()
        let staged = ready.stage(seven)
        let discarded = staged.receive(.discard(.hand(twoClubs)))
        XCTAssertNil(discarded.notice)
        XCTAssertEqual(discarded.playArea.cards, [seven])
        XCTAssertFalse(discarded.order.contains(seven))
        XCTAssertTrue(discarded.hand.you.cards.contains(seven))
        XCTAssertFalse(discarded.hand.you.cards.contains(twoClubs))
        XCTAssertFalse(discarded.playIsEnabled)
    }

    func testTheReadyMeldFixtureCanPlayTheHeartRun() {
        let session = TableLaunch.session(arguments: ["-tableFixture", TableLaunch.readyMeld])
        XCTAssertEqual(session.scene.phaseLabel, "Meld or discard")
        XCTAssertEqual(session.scene.turnLabel, "Your turn")
        XCTAssertTrue(session.order.contains(seven))
        XCTAssertTrue(session.order.contains(eight))
        XCTAssertTrue(session.order.contains(nine))
        let played = session.stage(seven).stage(eight).stage(nine).playStaged()
        XCTAssertEqual(played.hand.melds.count, 1)
        XCTAssertNil(played.notice)
    }

    private func readyToMeld() -> TableSession {
        TableSession(hand: HandState.scriptedPlay()[1], match: .opening, playsLive: false)
    }
}
