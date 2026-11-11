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
        XCTAssertEqual(
            CardDragRoute.intent(origin: .hand, zone: .playArea),
            .stage
        )
        XCTAssertEqual(
            CardDragRoute.intent(origin: .playArea, zone: .hand),
            .unstage
        )
        XCTAssertNil(CardDragRoute.intent(origin: .hand, zone: .hand))
        XCTAssertNil(CardDragRoute.intent(origin: .playArea, zone: .playArea))

        let play = CGRect(x: 0, y: 0, width: 200, height: 80)
        let hand = CGRect(x: 0, y: 200, width: 200, height: 80)
        let frames: [CardDropZone: CGRect] = [.playArea: play, .hand: hand]
        let dragged = DraggedCard.hand(seven)
        XCTAssertEqual(
            CardDragRoute.zone(for: dragged, at: CGPoint(x: 40, y: 40), in: frames),
            .playArea
        )
        XCTAssertEqual(
            CardDragRoute.zone(for: dragged, at: CGPoint(x: 40, y: 90), in: frames),
            .playArea
        )
        XCTAssertEqual(
            CardDragRoute.zone(for: dragged, at: CGPoint(x: 40, y: 220), in: frames),
            .hand
        )
        XCTAssertNil(CardDragRoute.zone(for: dragged, at: CGPoint(x: 40, y: 140), in: frames))

        let ready = readyToMeld()
        let staged = ready.receive(DraggedCard.hand(seven), in: .playArea)
        XCTAssertEqual(staged.playArea.cards, [seven])
        let back = staged.receive(DraggedCard.playArea(seven), in: .hand)
        XCTAssertTrue(back.playArea.cards.isEmpty)
        XCTAssertEqual(back.order.last, seven)
        XCTAssertEqual(staged.receive(DraggedCard.hand(seven), in: .hand).playArea.cards, [seven])
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

    func testADiscardKeepsTheStagedCards() {
        let ready = readyToMeld()
        let staged = ready.stage(seven)
        let discarded = staged.selecting([twoClubs]).discardSelection()
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
