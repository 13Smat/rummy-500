import XCTest
@testable import RummyEngine

final class TurnTests: XCTestCase {
    func testLegalStockDraw() throws {
        let state = HandState.deal(seed: Seed(0))
        let top = try XCTUnwrap(state.stock.topToBottom.first)
        let seat = state.turn
        let next = try state.drawFromStock().get()
        XCTAssertEqual(next.phase, .mayMeldOrDiscard)
        XCTAssertEqual(next.turn, seat)
        XCTAssertEqual(next.stock.count, state.stock.count - 1)
        XCTAssertEqual(next.stock.topToBottom, Array(state.stock.topToBottom.dropFirst()))
        XCTAssertEqual(next.cards(for: seat), state.cards(for: seat) + [top])
        XCTAssertEqual(next.discard, state.discard)
        XCTAssertEqual(next.melds, [])
        XCTAssertNil(next.handResult)
    }

    func testTakingTheTopDiscardAndMeldingItAtOnce() throws {
        let top = card(.four, .hearts)
        let state = opened(
            you: [card(.four, .clubs), card(.four, .diamonds), card(.nine, .hearts)],
            discard: [card(.two, .clubs), top]
        )
        let taken = try state.takeDiscard(top).get()
        XCTAssertEqual(taken.phase, .mustUsePickedCard(top))
        XCTAssertEqual(taken.discard.bottomToTop, [card(.two, .clubs)])
        XCTAssertEqual(taken.you.cards, state.you.cards + [top])
        let melded = try taken.layDown([
            card(.four, .clubs),
            card(.four, .diamonds),
            top,
        ]).get()
        XCTAssertEqual(melded.phase, .mayMeldOrDiscard)
        XCTAssertEqual(melded.you.cards, [card(.nine, .hearts)])
        XCTAssertEqual(melded.melds.count, 1)
        XCTAssertEqual(melded.melds[0].cards(playedBy: .you).contains(top), true)
        XCTAssertNil(melded.handResult)
    }

    func testTakingADeeperDiscardTakesEveryCardAboveIt() throws {
        let buried = card(.four, .spades)
        let above = [card(.two, .clubs), card(.three, .diamonds)]
        let below = card(.ace, .diamonds)
        let state = opened(
            you: [card(.four, .clubs), card(.four, .diamonds), card(.nine, .hearts)],
            discard: [below, buried] + above
        )
        let taken = try state.takeDiscard(buried).get()
        XCTAssertEqual(taken.discard.bottomToTop, [below])
        XCTAssertEqual(taken.you.cards, state.you.cards + [buried] + above)
        XCTAssertEqual(taken.phase, .mustUsePickedCard(buried))
        XCTAssertEqual(taken.stock, state.stock)
        XCTAssertEqual(taken.turn, .you)
    }

    func testCardsAboveThePickCanCompleteTheMeld() throws {
        let buried = card(.seven, .hearts)
        let state = opened(
            you: [card(.eight, .hearts), card(.five, .clubs)],
            stock: [card(.king, .spades)],
            discard: [buried, card(.six, .hearts), card(.nine, .hearts)]
        )
        let taken = try state.takeDiscard(buried).get()
        let melded = try taken.layDown([
            card(.six, .hearts),
            buried,
            card(.eight, .hearts),
            card(.nine, .hearts),
        ]).get()
        XCTAssertEqual(melded.you.cards, [card(.five, .clubs)])
        XCTAssertEqual(melded.phase, .mayMeldOrDiscard)
        XCTAssertEqual(melded.discard.bottomToTop, [])
    }

    func testADiscardPickThatIsNotPlayedAtOnceIsRejected() throws {
        let buried = card(.four, .spades)
        let state = opened(
            you: [
                card(.seven, .hearts),
                card(.eight, .hearts),
                card(.nine, .hearts),
                card(.four, .clubs),
                card(.four, .diamonds),
            ],
            discard: [buried, card(.two, .clubs)]
        )
        let taken = try state.takeDiscard(buried).get()
        assertUnchanged(
            taken,
            taken.discard(card(.nine, .hearts)),
            .mustMeldOrLayOffPickedCard(buried)
        )
        assertUnchanged(
            taken,
            taken.layDown([
                card(.seven, .hearts),
                card(.eight, .hearts),
                card(.nine, .hearts),
            ]),
            .pickedCardNotUsed
        )
        assertUnchanged(taken, taken.drawFromStock(), .mustMeldOrLayOffPickedCard(buried))
        assertUnchanged(
            taken,
            taken.layOff(card(.nine, .hearts), onMeldAt: 0),
            .pickedCardNotUsed
        )

        let unusable = card(.king, .diamonds)
        let fresh = opened(
            you: [card(.four, .clubs), card(.nine, .hearts), card(.two, .spades)],
            discard: [unusable]
        )
        assertUnchanged(fresh, fresh.takeDiscard(unusable), .discardCannotBeUsed)
        XCTAssertEqual(fresh.discard.bottomToTop, [unusable])
    }

    func testLayingOffThePickedCardClearsTheObligation() throws {
        let picked = card(.four, .hearts)
        let meld = try Meld.layDown(
            [card(.four, .clubs), card(.four, .diamonds), card(.four, .spades)],
            playedBy: .computer
        ).get()
        let state = opened(
            you: [card(.nine, .hearts), card(.two, .clubs), card(.king, .diamonds)],
            discard: [picked],
            melds: [meld]
        )
        let taken = try state.takeDiscard(picked).get()
        let laid = try taken.layOff(picked, onMeldAt: 0).get()
        XCTAssertEqual(laid.phase, .mayMeldOrDiscard)
        XCTAssertEqual(laid.melds[0].cards(playedBy: .you), [picked])
        XCTAssertFalse(laid.you.cards.contains(picked))
        XCTAssertEqual(
            laid.melds[0].cards(playedBy: .computer),
            [card(.four, .clubs), card(.four, .diamonds), card(.four, .spades)]
        )
    }

    func testADiscardPassesTheTurn() throws {
        let discarded = card(.nine, .hearts)
        let state = opened(
            you: [card(.four, .clubs), discarded],
            computer: [card(.ace, .spades)],
            phase: .mayMeldOrDiscard
        )
        let next = try state.discard(discarded).get()
        XCTAssertEqual(next.turn, .computer)
        XCTAssertEqual(next.phase, .awaitingDraw)
        XCTAssertEqual(next.discard.top, discarded)
        XCTAssertEqual(next.you.cards, [card(.four, .clubs)])
        XCTAssertEqual(next.computer.cards, state.computer.cards)
        XCTAssertNil(next.handResult)
    }

    func testMeldingTheLastCardsGoesOutWithoutADiscard() throws {
        let cards = [card(.seven, .hearts), card(.eight, .hearts), card(.nine, .hearts)]
        let state = opened(
            you: cards,
            computer: [card(.ace, .spades)],
            phase: .mayMeldOrDiscard
        )
        let next = try state.layDown(cards).get()
        XCTAssertEqual(next.phase, .handOver(.goneOut(.you)))
        XCTAssertEqual(next.you.cards, [])
        XCTAssertEqual(next.turn, .you)
        let result = try XCTUnwrap(next.handResult)
        XCTAssertEqual(result.score.you, 24)
        XCTAssertEqual(result.score.computer, -15)
        XCTAssertEqual(result.you.table, [
            card(.seven, .hearts),
            card(.eight, .hearts),
            card(.nine, .hearts),
        ])
        XCTAssertEqual(Match.opening.record(result).you, 24)
        XCTAssertEqual(Match.opening.record(result).computer, -15)
    }

    func testUsingThePickedCardForTheWholeHandGoesOut() throws {
        let picked = card(.nine, .hearts)
        let state = opened(
            you: [card(.seven, .hearts), card(.eight, .hearts)],
            discard: [picked]
        )
        let taken = try state.takeDiscard(picked).get()
        let next = try taken.layDown([
            card(.seven, .hearts),
            card(.eight, .hearts),
            picked,
        ]).get()
        XCTAssertEqual(next.phase, .handOver(.goneOut(.you)))
        XCTAssertEqual(next.you.cards, [])
        XCTAssertEqual(try XCTUnwrap(next.handResult).you.hand, [])
    }

    func testLayingOffTheLastCardGoesOut() throws {
        let last = card(.four, .hearts)
        let meld = try Meld.layDown(
            [card(.four, .clubs), card(.four, .diamonds), card(.four, .spades)],
            playedBy: .computer
        ).get()
        let state = opened(
            you: [last],
            melds: [meld],
            phase: .mayMeldOrDiscard
        )
        let next = try state.layOff(last, onMeldAt: 0).get()
        XCTAssertEqual(next.phase, .handOver(.goneOut(.you)))
        XCTAssertEqual(next.you.cards, [])
        XCTAssertEqual(try XCTUnwrap(next.handResult).you.table, [last])
    }

    func testDiscardingTheLastCardGoesOut() throws {
        let last = card(.five, .clubs)
        let state = opened(
            you: [last],
            computer: [card(.ace, .spades)],
            discard: [card(.two, .diamonds)],
            phase: .mayMeldOrDiscard
        )
        let next = try state.discard(last).get()
        XCTAssertEqual(next.phase, .handOver(.goneOut(.you)))
        XCTAssertEqual(next.turn, .you)
        XCTAssertEqual(next.you.cards, [])
        XCTAssertEqual(next.discard.top, last)
        let result = try XCTUnwrap(next.handResult)
        XCTAssertEqual(result.you.hand, [])
        XCTAssertEqual(result.you.table, [])
        XCTAssertEqual(result.score.you, 0)
        XCTAssertEqual(result.score.computer, -15)
        XCTAssertFalse(result.you.hand.contains(last))
        XCTAssertFalse(result.you.table.contains(last))
    }

    func testAnEmptyStockEndsTheHandWhenTheDiscardIsLeft() throws {
        let state = opened(
            you: [card(.two, .clubs), card(.five, .hearts), card(.nine, .diamonds)],
            computer: [card(.ace, .spades), card(.king, .clubs)],
            stock: [],
            discard: [card(.queen, .hearts)]
        )
        assertUnchanged(state, state.drawFromStock(), .stockIsEmpty)
        assertUnchanged(
            state,
            state.takeDiscard(card(.queen, .hearts)),
            .discardCannotBeUsed
        )
        let ended = try state.declineDiscardPile().get()
        XCTAssertEqual(ended.phase, .handOver(.stockExhausted))
        XCTAssertEqual(ended.you.cards, state.you.cards)
        XCTAssertEqual(ended.computer.cards, state.computer.cards)
        XCTAssertEqual(ended.discard, state.discard)
        let result = try XCTUnwrap(ended.handResult)
        XCTAssertEqual(result.you.hand, state.you.cards)
        XCTAssertEqual(result.computer.hand, state.computer.cards)
        XCTAssertEqual(result.score.you, -(2 + 5 + 9))
        XCTAssertEqual(result.score.computer, -(15 + 10))
        let match = Match.opening.record(result)
        XCTAssertEqual(match.you, result.score.you)
        XCTAssertEqual(match.computer, result.score.computer)
        XCTAssertEqual(match.hands, [result.score])
    }

    func testAnEmptyStockStillAllowsAUsableDiscardPick() throws {
        let top = card(.four, .hearts)
        let state = opened(
            you: [card(.four, .clubs), card(.four, .diamonds), card(.nine, .hearts)],
            stock: [],
            discard: [top]
        )
        let taken = try state.takeDiscard(top).get()
        XCTAssertEqual(taken.phase, .mustUsePickedCard(top))
        XCTAssertEqual(taken.stock.count, 0)
        XCTAssertNotEqual(taken.phase, .handOver(.stockExhausted))
    }

    func testIllegalMovesLeaveTheHandUnchanged() throws {
        let playable = opened(
            you: [card(.two, .clubs), card(.five, .hearts), card(.nine, .diamonds)],
            stock: [card(.king, .clubs)],
            discard: [card(.queen, .hearts)]
        )
        assertUnchanged(playable, playable.layDown([card(.two, .clubs)]), .stillDrawing)
        assertUnchanged(playable, playable.discard(card(.two, .clubs)), .stillDrawing)
        assertUnchanged(playable, playable.declineDiscardPile(), .stockStillHasCards)
        assertUnchanged(playable, playable.takeDiscard(card(.ace, .clubs)), .discardNotInPile)

        let drew = try playable.drawFromStock().get()
        assertUnchanged(drew, drew.drawFromStock(), .alreadyDrew)
        assertUnchanged(drew, drew.takeDiscard(card(.queen, .hearts)), .alreadyDrew)
        assertUnchanged(drew, drew.declineDiscardPile(), .alreadyDrew)
        assertUnchanged(drew, drew.discard(card(.ace, .spades)), .cardNotInHand)
        assertUnchanged(
            drew,
            drew.layDown([card(.two, .clubs), card(.five, .hearts)]),
            .meldRejected(.needsThreeCards)
        )
        assertUnchanged(drew, drew.layOff(card(.two, .clubs), onMeldAt: 0), .noSuchMeld)

        let over = try opened(
            you: [card(.five, .clubs)],
            phase: .mayMeldOrDiscard
        ).discard(card(.five, .clubs)).get()
        assertUnchanged(over, over.drawFromStock(), .handIsOver)
        assertUnchanged(over, over.discard(card(.five, .clubs)), .handIsOver)
        assertUnchanged(over, over.layDown([card(.five, .clubs)]), .handIsOver)
        assertUnchanged(over, over.declineDiscardPile(), .handIsOver)
    }

    func testScriptedHandPicksDeepAndScores() throws {
        let trace = HandState.scriptedPlay()
        let buried = card(.three, .hearts)
        let pickedIndex = try XCTUnwrap(trace.firstIndex { state in
            if case .mustUsePickedCard(let card) = state.phase {
                return card == buried
            }
            return false
        })
        let picked = trace[pickedIndex]
        let before = trace[pickedIndex - 1]
        XCTAssertGreaterThan(before.discard.count - picked.discard.count, 1)
        XCTAssertEqual(picked.discard.bottomToTop, [])
        XCTAssertTrue(picked.you.cards.contains(card(.five, .diamonds)))
        XCTAssertTrue(picked.you.cards.contains(card(.nine, .clubs)))
        XCTAssertTrue(picked.you.cards.contains(card(.four, .clubs)))
        XCTAssertTrue(picked.you.cards.contains(card(.six, .spades)))
        XCTAssertEqual(before.turn, .you)
        XCTAssertEqual(before.stock.count, 0)

        let final = try XCTUnwrap(trace.last)
        XCTAssertEqual(final.phase, .handOver(.stockExhausted))
        let result = try XCTUnwrap(final.handResult)
        XCTAssertEqual(result.score.you, 8)
        XCTAssertEqual(result.score.computer, -1)
        XCTAssertTrue(result.you.table.contains(buried))
        XCTAssertEqual(result.computer.hand, [card(.king, .clubs)])
        XCTAssertFalse(result.you.hand.contains(buried))
        let match = Match.opening.record(result)
        XCTAssertEqual(match.hands, [result.score])
        XCTAssertEqual(match.you, 8)
        XCTAssertEqual(match.computer, -1)
        XCTAssertEqual(match.conclusion, .playing)
    }
}

private func card(_ rank: Rank, _ suit: Suit) -> Card {
    Card(rank: rank, suit: suit)
}

private func opened(
    you: [Card],
    computer: [Card] = [Card(rank: .ace, suit: .spades)],
    stock: [Card] = [Card(rank: .king, suit: .clubs)],
    discard: [Card] = [Card(rank: .king, suit: .hearts)],
    melds: [Meld] = [],
    turn: Seat = .you,
    phase: HandState.Phase = .awaitingDraw
) -> HandState {
    HandState(
        you: Hand(cards: you),
        computer: Hand(cards: computer),
        stock: Stock(topToBottom: stock),
        discard: DiscardPile(bottomToTop: discard),
        melds: melds,
        turn: turn,
        phase: phase,
        seed: Seed(0),
        rotation: .opening
    )
}

private func assertUnchanged(
    _ state: HandState,
    _ result: Result<HandState, TurnRejection>,
    _ reason: TurnRejection,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let before = state
    XCTAssertEqual(result, .failure(reason), file: file, line: line)
    XCTAssertEqual(state, before, file: file, line: line)
}
