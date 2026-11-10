import XCTest
@testable import RummyEngine

final class ComputerOpponentTests: XCTestCase {
    func testSeatViewShowsOneHandAndThePublicTable() {
        let state = HandState.deal(seed: Seed(0))
        let view = SeatView(hand: state, seat: .computer, yourScore: 40, opponentScore: 15)
        let hidden = Set(state.you.cards).union(state.stock.topToBottom)
        let visible = Set(view.hand)
            .union(view.discardBottomToTop)
            .union(view.melds.flatMap(\.cards))

        XCTAssertEqual(view.seat, .computer)
        XCTAssertEqual(view.hand, state.computer.cards)
        XCTAssertEqual(view.discardBottomToTop, state.discard.bottomToTop)
        XCTAssertEqual(view.melds, state.melds)
        XCTAssertEqual(view.stockCount, state.stock.count)
        XCTAssertEqual(view.phase, state.phase)
        XCTAssertEqual(view.yourScore, 40)
        XCTAssertEqual(view.opponentScore, 15)
        XCTAssertTrue(visible.isDisjoint(with: hidden))
        XCTAssertFalse(view.hand.contains(state.you.cards[0]))
    }

    func testTakesTheTopDiscardWhenItMeldsAtOnce() {
        let top = card(.four, .hearts)
        let state = opened(
            you: [card(.four, .clubs), card(.four, .diamonds), card(.nine, .spades)],
            discard: [card(.two, .clubs), top]
        )
        let view = SeatView(hand: state, seat: .you, yourScore: 0, opponentScore: 0)
        XCTAssertEqual(ComputerOpponent.choose(view), .takeDiscard(top))
    }

    func testTakesABuriedCardWhenTheHaulScoresMoreThanTheExtraCards() throws {
        let buried = card(.seven, .hearts)
        let extra = card(.three, .clubs)
        let state = opened(
            you: [card(.eight, .hearts), card(.nine, .hearts), card(.king, .spades)],
            discard: [card(.ace, .diamonds), buried, extra]
        )
        let view = SeatView(hand: state, seat: .you, yourScore: 0, opponentScore: 10)
        XCTAssertEqual(ComputerOpponent.choose(view), .takeDiscard(buried))

        let taken = try ComputerTable.step(state, youScore: 0, computerScore: 10).get()
        XCTAssertEqual(taken.play, .takeDiscard(buried))
        let melded = try ComputerTable.step(taken.state, youScore: 0, computerScore: 10).get()
        guard case .layDown(let cards) = melded.play else {
            return XCTFail("expected a lay down, got \(melded.play)")
        }
        XCTAssertTrue(cards.contains(buried))
        XCTAssertEqual(melded.state.phase, .mayMeldOrDiscard)
    }

    func testDrawsWhenABuriedCardCostsMoreThanItScores() {
        let buried = card(.four, .hearts)
        let state = opened(
            you: [card(.three, .hearts), card(.five, .hearts), card(.nine, .clubs)],
            discard: [card(.ace, .diamonds), buried, card(.king, .spades)]
        )
        let view = SeatView(hand: state, seat: .you, yourScore: 500, opponentScore: 0)
        XCTAssertEqual(ComputerOpponent.choose(view), .drawFromStock)
        let sameCards = SeatView(hand: state, seat: .you, yourScore: 0, opponentScore: 500)
        XCTAssertEqual(ComputerOpponent.choose(sameCards), .drawFromStock)
    }

    func testLeavesThePileWhenTheStockIsEmptyAndNothingIsWorthTaking() throws {
        let state = opened(
            you: [card(.three, .hearts), card(.five, .hearts), card(.nine, .clubs)],
            stock: [],
            discard: [card(.four, .hearts), card(.king, .spades)]
        )
        let view = SeatView(hand: state, seat: .you, yourScore: 0, opponentScore: 0)
        XCTAssertEqual(ComputerOpponent.choose(view), .declineDiscardPile)
        let ended = try ComputerTable.step(state, youScore: 0, computerScore: 0).get()
        XCTAssertEqual(ended.state.phase, .handOver(.stockExhausted))
    }

    func testLaysOffACardThatFitsTheTable() throws {
        let run = try meld([card(.four, .hearts), card(.five, .hearts), card(.six, .hearts)])
        let seven = card(.seven, .hearts)
        let state = opened(
            you: [card(.ace, .spades)],
            computer: [seven, card(.king, .clubs), card(.two, .diamonds)],
            stock: [card(.nine, .clubs)],
            discard: [card(.queen, .diamonds)],
            melds: [run],
            turn: .computer,
            phase: .mayMeldOrDiscard
        )
        let view = SeatView(hand: state, seat: .computer, yourScore: 12, opponentScore: 4)
        XCTAssertEqual(ComputerOpponent.choose(view), .layOff(seven, meldIndex: 0))
        let laid = try ComputerTable.step(state, youScore: 4, computerScore: 12).get()
        XCTAssertEqual(laid.state.melds[0].cards(playedBy: .computer), [seven])
    }

    func testDiscardsTheLastCardAndGoesOut() throws {
        let last = card(.five, .clubs)
        let state = opened(
            you: [last],
            phase: .mayMeldOrDiscard
        )
        let view = SeatView(hand: state, seat: .you, yourScore: 0, opponentScore: 0)
        XCTAssertEqual(ComputerOpponent.choose(view), .discard(last))
        let ended = try ComputerTable.step(state, youScore: 0, computerScore: 0).get()
        XCTAssertEqual(ended.state.phase, .handOver(.goneOut(.you)))
        XCTAssertEqual(ended.state.you.cards, [])
    }

    func testSeededHandsFinishAndIncludePicksAndLayoffs() throws {
        let seeds = (0..<200).map(UInt64.init)
        let run = try ComputerTable.play(seeds: seeds).get()
        print("computer-run \(run)")
        XCTAssertGreaterThan(run.moves, 0)
        XCTAssertGreaterThan(run.discardPicks, 0)
        XCTAssertGreaterThan(run.deeperPicks, 0)
        XCTAssertGreaterThan(run.layoffs, 0)
    }

    func testBothSeatsFinishMatchesTo500() throws {
        for seed in UInt64(0)..<4 {
            let match = try ComputerTable.playMatch(seed: seed).get()
            print(
                "computer-match seed \(seed) hands \(match.hands.count) you \(match.you) computer \(match.computer)"
            )
            guard case .won(let winner) = match.conclusion else {
                return XCTFail("seed \(seed) did not finish")
            }
            let leader = match.you > match.computer ? Seat.you : Seat.computer
            XCTAssertEqual(winner, leader)
            XCTAssertGreaterThanOrEqual(max(match.you, match.computer), 500)
            XCTAssertEqual(try ComputerTable.playMatch(seed: seed).get(), match)
        }
    }

    func testSameSeedReplaysTheSameHand() throws {
        let first = try ComputerTable.play(seed: 18).get()
        let second = try ComputerTable.play(seed: 18).get()
        XCTAssertEqual(first, second)
        XCTAssertNotNil(first.handResult)
    }
}

private func card(_ rank: Rank, _ suit: Suit) -> Card {
    Card(rank: rank, suit: suit)
}

private func meld(_ cards: [Card]) throws -> Meld {
    try Meld.layDown(cards, playedBy: .you).get()
}

private func opened(
    you: [Card] = [Card(rank: .ace, suit: .spades)],
    computer: [Card] = [Card(rank: .ace, suit: .clubs)],
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
