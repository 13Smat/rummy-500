import XCTest
@testable import RummyEngine

final class MeldTests: XCTestCase {
    func testThreeOfAKindKeepsSuitOrderAndOneOwner() throws {
        let meld = try Meld.layDown(
            [card(.king, .spades), card(.king, .clubs), card(.king, .hearts)],
            playedBy: .you
        ).get()
        XCTAssertEqual(meld.kind, .set)
        XCTAssertEqual(
            meld.played,
            [
                played(.king, .clubs, .you),
                played(.king, .hearts, .you),
                played(.king, .spades, .you),
            ]
        )
        XCTAssertEqual(meld.cards(playedBy: .computer), [])
    }

    func testFourOfAKindIsASet() throws {
        let meld = try Meld.layDown(
            [
                card(.seven, .hearts),
                card(.seven, .spades),
                card(.seven, .diamonds),
                card(.seven, .clubs),
            ],
            playedBy: .computer
        ).get()
        XCTAssertEqual(meld.kind, .set)
        XCTAssertEqual(
            meld.cards,
            [
                card(.seven, .clubs),
                card(.seven, .diamonds),
                card(.seven, .hearts),
                card(.seven, .spades),
            ]
        )
        XCTAssertEqual(meld.cards(playedBy: .computer), meld.cards)
    }

    func testSuitedRunOfThreeOrMoreStaysInRankOrder() throws {
        let three = try Meld.layDown(
            [card(.five, .hearts), card(.three, .hearts), card(.four, .hearts)],
            playedBy: .you
        ).get()
        XCTAssertEqual(three.kind, .run)
        XCTAssertEqual(
            three.cards,
            [card(.three, .hearts), card(.four, .hearts), card(.five, .hearts)]
        )

        let five = try Meld.layDown(
            [
                card(.king, .diamonds),
                card(.ten, .diamonds),
                card(.queen, .diamonds),
                card(.jack, .diamonds),
                card(.nine, .diamonds),
            ],
            playedBy: .you
        ).get()
        XCTAssertEqual(
            five.cards,
            [
                card(.nine, .diamonds),
                card(.ten, .diamonds),
                card(.jack, .diamonds),
                card(.queen, .diamonds),
                card(.king, .diamonds),
            ]
        )
    }

    func testAceLowRun() throws {
        let meld = try Meld.layDown(
            [card(.three, .clubs), card(.ace, .clubs), card(.two, .clubs)],
            playedBy: .you
        ).get()
        XCTAssertEqual(meld.kind, .run)
        XCTAssertEqual(
            meld.cards,
            [card(.ace, .clubs), card(.two, .clubs), card(.three, .clubs)]
        )
    }

    func testAceHighRun() throws {
        let meld = try Meld.layDown(
            [card(.ace, .spades), card(.queen, .spades), card(.king, .spades)],
            playedBy: .you
        ).get()
        XCTAssertEqual(
            meld.cards,
            [card(.queen, .spades), card(.king, .spades), card(.ace, .spades)]
        )
    }

    func testKingAceTwoWraps() {
        XCTAssertEqual(
            Meld.layDown(
                [card(.king, .hearts), card(.ace, .hearts), card(.two, .hearts)],
                playedBy: .you
            ),
            .failure(.wrapsAround)
        )
        XCTAssertEqual(
            Meld.layDown(
                [
                    card(.king, .hearts),
                    card(.ace, .hearts),
                    card(.two, .hearts),
                    card(.three, .hearts),
                ],
                playedBy: .you
            ),
            .failure(.wrapsAround)
        )
    }

    func testWholeSuitWraps() {
        let suit = Rank.allCases.map { card($0, .clubs) }
        XCTAssertEqual(Meld.layDown(suit, playedBy: .you), .failure(.wrapsAround))
    }

    func testMixedSuitRunIsRejected() {
        XCTAssertEqual(
            Meld.layDown(
                [card(.four, .hearts), card(.five, .diamonds), card(.six, .hearts)],
                playedBy: .you
            ),
            .failure(.mixedSuit)
        )
    }

    func testFiveOfAKindIsRejected() {
        let aces = Suit.allCases.map { card(.ace, $0) }
        XCTAssertEqual(
            Meld.layDown(aces + [card(.ace, .spades)], playedBy: .you),
            .failure(.fiveOfAKind)
        )
    }

    func testShortGroupAndAGapAndADuplicate() {
        XCTAssertEqual(
            Meld.layDown([card(.ace, .hearts), card(.two, .hearts)], playedBy: .you),
            .failure(.needsThreeCards)
        )
        XCTAssertEqual(
            Meld.layDown(
                [card(.two, .spades), card(.three, .spades), card(.five, .spades)],
                playedBy: .you
            ),
            .failure(.notInSequence)
        )
        XCTAssertEqual(
            Meld.layDown(
                [card(.ace, .spades), card(.ace, .spades), card(.ace, .hearts)],
                playedBy: .you
            ),
            .failure(.duplicateCard)
        )
    }

    func testLayOffCompletesASetAndCreditsTheOtherPlayer() throws {
        let meld = try Meld.layDown(
            [card(.king, .clubs), card(.king, .hearts), card(.king, .spades)],
            playedBy: .you
        ).get()
        let next = try meld.layOff(card(.king, .diamonds), playedBy: .computer).get()
        XCTAssertEqual(
            next.played,
            [
                played(.king, .clubs, .you),
                played(.king, .diamonds, .computer),
                played(.king, .hearts, .you),
                played(.king, .spades, .you),
            ]
        )
        XCTAssertEqual(next.cards(playedBy: .you).count, 3)
        XCTAssertEqual(next.cards(playedBy: .computer), [card(.king, .diamonds)])
    }

    func testIllegalLayoffsOnASet() throws {
        let three = try Meld.layDown(
            [card(.five, .clubs), card(.five, .hearts), card(.five, .spades)],
            playedBy: .computer
        ).get()
        XCTAssertEqual(
            three.layOff(card(.six, .diamonds), playedBy: .you),
            .failure(.doesNotFit)
        )

        let four = try Meld.layDown(
            Suit.allCases.map { card(.eight, $0) },
            playedBy: .you
        ).get()
        XCTAssertEqual(
            four.layOff(card(.eight, .spades), playedBy: .computer),
            .failure(.duplicateCard)
        )
    }

    func testRunExtendsAtEitherEnd() throws {
        let meld = try Meld.layDown(
            [card(.five, .clubs), card(.six, .clubs), card(.seven, .clubs)],
            playedBy: .you
        ).get()
        let lower = try meld.layOff(card(.four, .clubs), playedBy: .you).get()
        XCTAssertEqual(
            lower.cards,
            [
                card(.four, .clubs),
                card(.five, .clubs),
                card(.six, .clubs),
                card(.seven, .clubs),
            ]
        )
        let higher = try meld.layOff(card(.eight, .clubs), playedBy: .computer).get()
        XCTAssertEqual(
            higher.cards,
            [
                card(.five, .clubs),
                card(.six, .clubs),
                card(.seven, .clubs),
                card(.eight, .clubs),
            ]
        )
        XCTAssertEqual(higher.cards(playedBy: .computer), [card(.eight, .clubs)])
        XCTAssertEqual(higher.cards(playedBy: .you), meld.cards)
    }

    func testAceLaysOffOnEitherEnd() throws {
        let low = try Meld.layDown(
            [card(.two, .hearts), card(.three, .hearts), card(.four, .hearts)],
            playedBy: .computer
        ).get()
        let aceLow = try low.layOff(card(.ace, .hearts), playedBy: .you).get()
        XCTAssertEqual(
            aceLow.cards,
            [
                card(.ace, .hearts),
                card(.two, .hearts),
                card(.three, .hearts),
                card(.four, .hearts),
            ]
        )
        XCTAssertEqual(aceLow.cards(playedBy: .you), [card(.ace, .hearts)])

        let high = try Meld.layDown(
            [card(.jack, .diamonds), card(.queen, .diamonds), card(.king, .diamonds)],
            playedBy: .you
        ).get()
        let aceHigh = try high.layOff(card(.ace, .diamonds), playedBy: .computer).get()
        XCTAssertEqual(
            aceHigh.cards,
            [
                card(.jack, .diamonds),
                card(.queen, .diamonds),
                card(.king, .diamonds),
                card(.ace, .diamonds),
            ]
        )
        XCTAssertEqual(aceHigh.cards(playedBy: .computer), [card(.ace, .diamonds)])
    }

    func testIllegalLayoffsOnARun() throws {
        let meld = try Meld.layDown(
            [card(.five, .spades), card(.six, .spades), card(.seven, .spades)],
            playedBy: .you
        ).get()
        XCTAssertEqual(
            meld.layOff(card(.nine, .spades), playedBy: .you),
            .failure(.doesNotFit)
        )
        XCTAssertEqual(
            meld.layOff(card(.four, .hearts), playedBy: .computer),
            .failure(.mixedSuit)
        )
        XCTAssertEqual(
            meld.layOff(card(.ace, .spades), playedBy: .you),
            .failure(.doesNotFit)
        )

        let aceLow = try Meld.layDown(
            [card(.ace, .clubs), card(.two, .clubs), card(.three, .clubs)],
            playedBy: .you
        ).get()
        XCTAssertEqual(
            aceLow.layOff(card(.king, .clubs), playedBy: .computer),
            .failure(.wrapsAround)
        )

        let aceHigh = try Meld.layDown(
            [card(.queen, .hearts), card(.king, .hearts), card(.ace, .hearts)],
            playedBy: .computer
        ).get()
        XCTAssertEqual(
            aceHigh.layOff(card(.two, .hearts), playedBy: .you),
            .failure(.wrapsAround)
        )
        let extended = try aceHigh.layOff(card(.jack, .hearts), playedBy: .you).get()
        XCTAssertEqual(extended.cards.first, card(.jack, .hearts))
        XCTAssertEqual(extended.cards(playedBy: .you), [card(.jack, .hearts)])
    }

    func testTableCardsStayWithThePlayerWhoPlayedThem() throws {
        let set = try Meld.layDown(
            [card(.nine, .clubs), card(.nine, .hearts), card(.nine, .spades)],
            playedBy: .you
        ).get()
        let withFourth = try set.layOff(card(.nine, .diamonds), playedBy: .computer).get()
        let run = try Meld.layDown(
            [card(.four, .hearts), card(.five, .hearts), card(.six, .hearts)],
            playedBy: .computer
        ).get()
        let melds = [withFourth, run]
        XCTAssertEqual(
            melds.flatMap { $0.cards(playedBy: .you) },
            [card(.nine, .clubs), card(.nine, .hearts), card(.nine, .spades)]
        )
        XCTAssertEqual(
            melds.flatMap { $0.cards(playedBy: .computer) },
            [
                card(.nine, .diamonds),
                card(.four, .hearts),
                card(.five, .hearts),
                card(.six, .hearts),
            ]
        )
    }

    func testLargestGroupsFindsSetsAndBothAceRuns() {
        let cards = [
            card(.nine, .spades),
            card(.ace, .diamonds),
            card(.nine, .clubs),
            card(.two, .diamonds),
            card(.queen, .diamonds),
            card(.nine, .hearts),
            card(.three, .diamonds),
            card(.four, .diamonds),
            card(.king, .diamonds),
            card(.ace, .diamonds),
        ]
        let groups = Meld.largestGroups(in: cards, playedBy: .you)
        XCTAssertEqual(groups.map(\.kind), [.set, .run, .run])
        XCTAssertEqual(
            groups.map(\.cards),
            [
                [card(.nine, .clubs), card(.nine, .hearts), card(.nine, .spades)],
                [
                    card(.ace, .diamonds),
                    card(.two, .diamonds),
                    card(.three, .diamonds),
                    card(.four, .diamonds),
                ],
                [card(.queen, .diamonds), card(.king, .diamonds), card(.ace, .diamonds)],
            ]
        )
    }

    func testLargestGroupsOmitsARunInsideALongerRun() {
        let cards = [
            card(.three, .hearts),
            card(.four, .hearts),
            card(.five, .hearts),
            card(.six, .hearts),
        ]
        let groups = Meld.largestGroups(in: cards, playedBy: .computer)
        XCTAssertEqual(groups.map(\.cards), [cards])
        XCTAssertEqual(
            Meld.layDown(
                [card(.three, .hearts), card(.four, .hearts), card(.five, .hearts)],
                playedBy: .computer
            ).map(\.kind),
            .success(.run)
        )
    }

    func testOpeningComputerHandHasOneRun() {
        let deal = Deal.deal(seed: Seed(0))
        XCTAssertEqual(Meld.largestGroups(in: deal.you.cards, playedBy: .you), [])
        let computer = Meld.largestGroups(in: deal.computer.cards, playedBy: .computer)
        XCTAssertEqual(
            computer.map(\.cards),
            [[
                card(.five, .clubs),
                card(.six, .clubs),
                card(.seven, .clubs),
                card(.eight, .clubs),
            ]]
        )
    }

    func testLargestGroupsKeepsTheDistinctFourInsideARepeatedFifth() {
        let distinct = Suit.allCases.map { card(.ace, $0) }
        let groups = Meld.largestGroups(in: distinct + [card(.ace, .clubs)], playedBy: .you)
        XCTAssertEqual(groups.map(\.cards), [distinct])
        XCTAssertEqual(
            Meld.largestGroups(
                in: [card(.ace, .hearts), card(.two, .clubs)],
                playedBy: .you
            ),
            []
        )
    }

    private func card(_ rank: Rank, _ suit: Suit) -> Card {
        Card(rank: rank, suit: suit)
    }

    private func played(_ rank: Rank, _ suit: Suit, _ player: Seat) -> PlayedCard {
        PlayedCard(card: card(rank, suit), player: player)
    }
}
