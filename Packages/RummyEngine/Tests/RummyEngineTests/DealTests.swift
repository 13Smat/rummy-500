import XCTest
@testable import RummyEngine

final class DealTests: XCTestCase {
    func testOpeningDealUsesEveryCardOnce() {
        for rawSeed in [UInt64(0), 1, 42, UInt64.max] {
            let deal = Deal.deal(seed: Seed(rawSeed))
            XCTAssertEqual(deal.you.count, 13)
            XCTAssertEqual(deal.computer.count, 13)
            XCTAssertEqual(deal.stock.count, 25)
            XCTAssertEqual(deal.discard.count, 1)
            let dealt =
                deal.you.cards
                + deal.computer.cards
                + deal.stock.topToBottom
                + deal.discard.bottomToTop
            XCTAssertEqual(dealt.count, 52)
            XCTAssertEqual(Set(dealt), Set(Deck.standard.topToBottom))
        }
    }

    func testSameSeedDealsTheSameHand() {
        XCTAssertEqual(Deal.deal(seed: Seed(42)), Deal.deal(seed: Seed(42)))
    }

    func testDifferentSeedsDealDifferently() {
        XCTAssertNotEqual(Deal.deal(seed: Seed(0)), Deal.deal(seed: Seed(1)))
    }

    func testDealCutsTheShuffledDeckFromTheTop() {
        let seed = Seed(11)
        var generator = SeededGenerator(seed: seed)
        let shuffled = Deck.standard.shuffled(using: &generator).topToBottom
        let deal = Deal.deal(seed: seed)
        XCTAssertEqual(deal.you.cards[0], shuffled[0])
        XCTAssertEqual(deal.computer.cards[0], shuffled[1])
        XCTAssertEqual(deal.you.cards[1], shuffled[2])
        XCTAssertEqual(deal.discard.bottomToTop, [shuffled[26]])
        XCTAssertEqual(deal.discard.top, shuffled[26])
        XCTAssertEqual(deal.stock.topToBottom, Array(shuffled.dropFirst(27)))
    }

    func testSeedZeroDealsKnownCards() {
        let deal = Deal.deal(seed: Seed(0))
        XCTAssertEqual(deal.you.cards[0], Card(rank: .eight, suit: .spades))
        XCTAssertEqual(deal.computer.cards[0], Card(rank: .jack, suit: .hearts))
        XCTAssertEqual(deal.you.cards[1], Card(rank: .nine, suit: .clubs))
        XCTAssertEqual(deal.discard.top, Card(rank: .eight, suit: .diamonds))
        XCTAssertEqual(deal.dealer, .computer)
        XCTAssertEqual(deal.leader, .you)
    }

    func testSeedOneDealsKnownCards() {
        let deal = Deal.deal(seed: Seed(1))
        XCTAssertEqual(deal.you.cards[0], Card(rank: .seven, suit: .diamonds))
        XCTAssertEqual(deal.computer.cards[0], Card(rank: .nine, suit: .clubs))
        XCTAssertEqual(deal.you.cards[1], Card(rank: .four, suit: .diamonds))
        XCTAssertEqual(deal.discard.top, Card(rank: .ten, suit: .diamonds))
    }

    func testTheOtherDealerSwapsTheHands() {
        let seed = Seed(5)
        let computerDeals = Deal.deal(seed: seed, rotation: DealRotation(dealer: .computer))
        let youDeal = Deal.deal(seed: seed, rotation: DealRotation(dealer: .you))
        XCTAssertEqual(computerDeals.you.cards, youDeal.computer.cards)
        XCTAssertEqual(computerDeals.computer.cards, youDeal.you.cards)
        XCTAssertEqual(computerDeals.stock, youDeal.stock)
        XCTAssertEqual(computerDeals.discard, youDeal.discard)
        XCTAssertEqual(youDeal.leader, .computer)
    }

    func testOpeningRotationLetsYouLeadAndThenAlternates() {
        XCTAssertEqual(DealRotation.opening.dealer, .computer)
        XCTAssertEqual(DealRotation.opening.leader, .you)
        let next = DealRotation.opening.nextHand()
        XCTAssertEqual(next.dealer, .you)
        XCTAssertEqual(next.leader, .computer)
        XCTAssertEqual(next.nextHand(), DealRotation.opening)
    }
}
