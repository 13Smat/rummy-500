import XCTest
import RummyEngine
@testable import Rummy500

final class TableSessionTests: XCTestCase {
    func testDrawDiscardAndTheComputerReturnsTheTurn() {
        var session = TableSession.opening(seed: 0, playsLive: false)
        XCTAssertEqual(session.scene.turnLabel, "Your turn")
        XCTAssertEqual(session.scene.phaseLabel, "Draw a card")

        let blocked = session.receive(.discard(.hand(session.order[0])))
        XCTAssertEqual(blocked.hand, session.hand)
        XCTAssertEqual(blocked.notice, "Draw a card before you play.")

        session = session.drawFromStock()
        XCTAssertEqual(session.scene.phaseLabel, "Meld or discard")
        XCTAssertEqual(session.hand.you.cards.count, 14)
        XCTAssertNil(session.notice)
        let drawn = session.hand
        let again = session.drawFromStock()
        XCTAssertEqual(again.hand, drawn)
        XCTAssertEqual(again.notice, "You already drew. Meld, lay off, or discard.")

        session = session.receive(.discard(.hand(session.order[0])))
        XCTAssertEqual(session.hand.turn, .computer)
        XCTAssertNil(session.notice)
        var steps = 0
        while session.hand.turn == .computer && session.hand.handResult == nil && steps < 40 {
            let before = session.hand
            session = session.stepComputer()
            XCTAssertNotEqual(session.hand, before, "computer step \(steps)")
            XCTAssertNotNil(session.computerLine)
            steps += 1
        }
        XCTAssertGreaterThan(steps, 0)
        XCTAssertEqual(session.scene.turnLabel, "Your turn")
        XCTAssertEqual(session.hand.phase, .awaitingDraw)
    }

    func testALiveDiscardArmsTheComputerTurn() {
        let dealt = TableSession.opening(seed: 0, playsLive: true)
        let drawn = dealt.drawFromStock()
        let discarded = drawn.receive(.discard(.hand(drawn.order[0])))
        XCTAssertEqual(discarded.hand.turn, .computer)
        XCTAssertTrue(discarded.computerPending)
        XCTAssertGreaterThan(discarded.beat, 0)
    }

    func testDeeperDiscardPickTakesTheCardsAboveIt() throws {
        let buried = Card(rank: .three, suit: .diamonds)
        let before = TableSession(
            hand: TablePresets.handBeforeLongPick(),
            match: .opening,
            playsLive: false
        )
        let pile = before.hand.discard.bottomToTop
        let index = try XCTUnwrap(pile.firstIndex(of: buried))
        XCTAssertLessThan(index, pile.count - 1)
        let taken = Array(pile[index...])
        let after = before.takeDiscard(buried)
        XCTAssertNil(after.notice)
        XCTAssertEqual(after.owedCard, buried)
        XCTAssertEqual(after.mustUseText, "Play the 3 of diamonds before you do anything else.")
        XCTAssertEqual(after.hand.discard.bottomToTop, Array(pile[..<index]))
        for card in taken {
            XCTAssertTrue(after.order.contains(card))
        }
        XCTAssertEqual(after.order.count, before.order.count + taken.count)

        let others = after.order.filter { $0 != buried }
        let leftOut = others.prefix(3).reduce(after) { $0.stage($1) }.playStaged()
        XCTAssertEqual(leftOut.hand, after.hand)
        XCTAssertEqual(leftOut.notice, "Include the card you took from the discard.")

        let other = try XCTUnwrap(others.first)
        let discarded = after.receive(.discard(.hand(other)))
        XCTAssertEqual(discarded.hand, after.hand)
        XCTAssertEqual(
            discarded.notice,
            "Play the 3 of diamonds in a meld or a layoff first."
        )
    }

    func testLayOffOnTheOpponentsMeldClearsThePickedCard() throws {
        let trace = HandState.scriptedPlay()
        let buried = Card(rank: .three, suit: .hearts)
        let ready = TableSession(hand: trace[6], match: .opening, playsLive: false)
        XCTAssertEqual(ready.drawFromStock().notice, "The stock is empty.")
        XCTAssertEqual(ready.drawFromStock().hand, ready.hand)

        let taken = ready.takeDiscard(buried)
        XCTAssertEqual(taken.hand, trace[7])
        XCTAssertEqual(taken.mustUseText, "Play the 3 of hearts before you do anything else.")
        XCTAssertTrue(taken.order.contains(Card(rank: .five, suit: .diamonds)))
        XCTAssertTrue(taken.order.contains(Card(rank: .nine, suit: .clubs)))
        XCTAssertTrue(taken.hand.discard.bottomToTop.isEmpty)

        let laid = taken.stage(buried).playStaged()
        XCTAssertNil(laid.notice)
        XCTAssertNil(laid.owedCard)
        XCTAssertEqual(laid.hand, trace[8])
        XCTAssertEqual(laid.hand.melds[1].cards(playedBy: .you), [buried])
        XCTAssertEqual(laid.scene.melds[1].laidDownBy, .computer)
    }

    func testAnUnusableDiscardAndABadMeldLeaveTheHandAlone() {
        let opening = TableSession(hand: HandState.scriptedPlay()[0], match: .opening, playsLive: false)
        let top = Card(rank: .nine, suit: .clubs)
        let refused = opening.takeDiscard(top)
        XCTAssertEqual(
            refused.notice,
            "Take that card only when you can meld it or lay it off right away."
        )
        XCTAssertEqual(refused.hand, opening.hand)

        let missing = opening.takeDiscard(Card(rank: .ace, suit: .spades))
        XCTAssertEqual(missing.notice, "That card is not in the discard pile.")
        XCTAssertEqual(missing.hand, opening.hand)

        let fresh = TableSession.opening(seed: 0, playsLive: false)
        XCTAssertEqual(fresh.playStaged().notice, "Move cards into the play area first.")
        XCTAssertEqual(fresh.playStaged().hand, fresh.hand)
        XCTAssertEqual(fresh.tapTurn().hand, fresh.hand)

        let drawn = fresh.drawFromStock()
        let two = drawn.order.prefix(2).reduce(drawn) { $0.stage($1) }.playStaged()
        XCTAssertEqual(two.notice, "A new meld needs at least three cards.")
        XCTAssertEqual(two.hand, drawn.hand)

        let nowhere = drawn.stage(drawn.order[0]).playStaged()
        XCTAssertEqual(nowhere.notice, "A new meld needs at least three cards.")
        XCTAssertEqual(nowhere.hand, drawn.hand)

        let waiting = TableSession(preset: .midHand, playsLive: false)
        XCTAssertEqual(waiting.drawFromStock().notice, "Wait for the computer.")
        XCTAssertEqual(waiting.drawFromStock().hand, waiting.hand)
    }

    func testACardThatDoesNotFitStaysInTheHand() throws {
        let trace = HandState.scriptedPlay()
        let laid = TableSession(hand: trace[8], match: .opening, playsLive: false)
        let two = Card(rank: .two, suit: .clubs)
        let missed = laid.stage(two).playStaged()
        XCTAssertEqual(missed.hand, laid.hand)
        XCTAssertEqual(missed.notice, "A new meld needs at least three cards.")
    }

    func testSortAndMoveKeepTheSameCards() {
        let dealt = TableSession.opening(seed: 0, playsLive: false)
        let dealtCards = dealt.hand.you.cards
        let byRank = dealt.sortByRank()
        XCTAssertEqual(byRank.order.map(\.rank.rawValue), byRank.order.map(\.rank.rawValue).sorted())
        XCTAssertEqual(Set(byRank.order), Set(dealtCards))
        XCTAssertEqual(byRank.hand.you.cards, dealtCards)

        let bySuit = byRank.sortBySuit()
        XCTAssertEqual(bySuit.order, TableScene.sortedHand(dealtCards))
        let first = bySuit.order[0]
        let moved = bySuit.nudge(first, by: 1)
        XCTAssertEqual(moved.order[1], first)
        XCTAssertEqual(moved.order[0], bySuit.order[1])
        XCTAssertEqual(Set(moved.order), Set(dealtCards))
        XCTAssertEqual(moved.hand, dealt.hand)

        let stuck = moved.nudge(moved.order[0], by: -1)
        XCTAssertEqual(stuck.order, moved.order)
        XCTAssertNil(stuck.notice)
    }

    func testGoingOutDealsTheNextHandWithTheScore() throws {
        let ended = try XCTUnwrap(sessionWhereYouGoOut(), "no seed in 0..<200 ended with you going out")
        XCTAssertEqual(ended.scene.phaseLabel, "You went out")
        XCTAssertEqual(ended.scene.turnLabel, "Hand over")
        XCTAssertTrue(ended.order.isEmpty)
        let result = try XCTUnwrap(ended.hand.handResult)
        XCTAssertEqual(result.you.hand, [])
        XCTAssertEqual(ended.match.you, result.score.you)
        XCTAssertEqual(ended.match.computer, result.score.computer)
        XCTAssertEqual(ended.match.hands.count, 1)
        XCTAssertEqual(ended.handResultText, "This hand: you \(result.score.you), computer \(result.score.computer).")

        let next = ended.tapTurn()
        XCTAssertEqual(next.match, ended.match)
        XCTAssertEqual(next.hand.you.cards.count, 13)
        XCTAssertEqual(next.hand.computer.cards.count, 13)
        XCTAssertEqual(next.hand.phase, .awaitingDraw)
        XCTAssertNil(next.hand.handResult)
        XCTAssertNotEqual(next.hand.seed, ended.hand.seed)
        XCTAssertEqual(next.scene.yourScore, ended.match.you)
        XCTAssertEqual(next.scene.computerScore, ended.match.computer)
    }

    func testRefusalSentencesStayPlain() {
        let card = Card(rank: .four, suit: .hearts)
        let lines = [
            TurnWords.saying(.handIsOver),
            TurnWords.saying(.stillDrawing),
            TurnWords.saying(.alreadyDrew),
            TurnWords.saying(.stockIsEmpty),
            TurnWords.saying(.stockStillHasCards),
            TurnWords.saying(.discardNotInPile),
            TurnWords.saying(.discardCannotBeUsed),
            TurnWords.saying(.mustMeldOrLayOffPickedCard(card)),
            TurnWords.saying(.pickedCardNotUsed),
            TurnWords.saying(.cardNotInHand),
            TurnWords.saying(.noSuchMeld),
            TurnWords.saying(.meldRejected(.needsThreeCards)),
            TurnWords.saying(.meldRejected(.fiveOfAKind)),
            TurnWords.saying(.meldRejected(.duplicateCard)),
            TurnWords.saying(.meldRejected(.mixedSuit)),
            TurnWords.saying(.meldRejected(.wrapsAround)),
            TurnWords.saying(.meldRejected(.notInSequence)),
            TurnWords.saying(.meldRejected(.doesNotFit)),
        ]
        XCTAssertEqual(Set(lines).count, lines.count)
        for line in lines {
            XCTAssertFalse(line.isEmpty)
            let lowered = line.lowercased()
            for shame in ["illegal", "invalid", "wrong", "bad", "stupid", "fail", "error"] {
                XCTAssertFalse(lowered.contains(shame), line)
            }
        }
        XCTAssertEqual(TurnWords.saying(.meldRejected(.doesNotFit)), "That card does not fit this meld.")
        XCTAssertEqual(
            TurnWords.computer(.discard(card)),
            "Computer discarded the 4 of hearts."
        )
    }

    private func sessionWhereYouGoOut() -> TableSession? {
        for seed in UInt64(0)..<200 {
            var session = TableSession.opening(seed: seed, playsLive: false)
            for _ in 0..<400 {
                if case .handOver(.goneOut(.you)) = session.hand.phase {
                    return session
                }
                if session.hand.handResult != nil {
                    break
                }
                let next = session.hand.turn == .you
                    ? applyYourChoice(session)
                    : session.stepComputer()
                if next.hand == session.hand {
                    break
                }
                session = next
            }
        }
        return nil
    }

    func testPlacingACardKeepsTheFullOrderIndexMovingRightAndLeft() {
        let dealt = TableSession.opening(seed: 0, playsLive: false)
        let order = dealt.order
        let movingRight = order[0]
        let movedRight = dealt.receive(.placeInHand(.hand(movingRight), at: 2))
        var expectedRight = order
        expectedRight.remove(at: 0)
        expectedRight.insert(movingRight, at: 2)
        XCTAssertEqual(movedRight.order, expectedRight)
        XCTAssertEqual(movedRight.order[2], movingRight)
        XCTAssertEqual(movedRight.hand, dealt.hand)

        let movingLeft = order[order.count - 1]
        let movedLeft = dealt.receive(.placeInHand(.hand(movingLeft), at: 0))
        var expectedLeft = order
        expectedLeft.removeLast()
        expectedLeft.insert(movingLeft, at: 0)
        XCTAssertEqual(movedLeft.order, expectedLeft)
        XCTAssertEqual(movedLeft.order[0], movingLeft)
        XCTAssertEqual(movedLeft.hand, dealt.hand)

        let middle = order[1]
        let nudgedRight = dealt.nudge(middle, by: 1)
        var expectedNudgeRight = order
        expectedNudgeRight.remove(at: 1)
        expectedNudgeRight.insert(middle, at: 2)
        XCTAssertEqual(nudgedRight.order, expectedNudgeRight)

        let nudgedLeft = dealt.nudge(middle, by: -1)
        var expectedNudgeLeft = order
        expectedNudgeLeft.remove(at: 1)
        expectedNudgeLeft.insert(middle, at: 0)
        XCTAssertEqual(nudgedLeft.order, expectedNudgeLeft)
    }

    func testCuesFollowThePhaseAndTheEmptyStockLeavesThePile() {
        let dealt = TableSession.opening(seed: 0, playsLive: false)
        XCTAssertEqual(dealt.cue, .draw)
        XCTAssertFalse(dealt.accepts(.discard(.hand(dealt.order[0]))))
        let refused = dealt.receive(.discard(.hand(dealt.order[0])))
        XCTAssertEqual(refused.notice, "Draw a card before you play.")

        let drawn = dealt.drawFromStock()
        XCTAssertEqual(drawn.cue, .discard)
        XCTAssertTrue(drawn.accepts(.discard(.hand(drawn.order[0]))))

        let empty = TableSession(hand: HandState.scriptedPlay()[6], match: .opening, playsLive: false)
        XCTAssertEqual(empty.cue, .pass)
        let left = empty.tapStock()
        XCTAssertEqual(left.hand.phase, .handOver(.stockExhausted))
        XCTAssertEqual(dealt.tapTurn().hand, dealt.hand)
        XCTAssertEqual(left.cue, .handOver)
        XCTAssertEqual(left.tapTurn().hand.you.cards.count, 13)
    }

    private func applyYourChoice(_ session: TableSession) -> TableSession {
        let view = SeatView(
            hand: session.hand,
            seat: .you,
            yourScore: session.match.you,
            opponentScore: session.match.computer
        )
        switch ComputerOpponent.choose(view) {
        case .drawFromStock:
            return session.drawFromStock()
        case .takeDiscard(let card):
            return session.takeDiscard(card)
        case .declineDiscardPile:
            return session.tapStock()
        case .layDown(let cards):
            return cards.reduce(session) { $0.stage($1) }.playStaged()
        case .layOff(let card, meldIndex: _):
            return session.stage(card).playStaged()
        case .discard(let card):
            return session.receive(.discard(.hand(card)))
        }
    }
}
