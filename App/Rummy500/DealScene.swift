import Foundation
import RummyEngine

struct DealScene: Equatable {
    let seed: UInt64
    let dealerName: String
    let leaderName: String
    let yourHand: [String]
    let computerHand: [String]
    let stockCount: Int
    let discard: [String]

    static func load(seed: UInt64, rotation: DealRotation = .opening) -> DealScene {
        let deal = DemoSession.deal(seed: seed, rotation: rotation)
        return DealScene(
            seed: seed,
            dealerName: seatName(deal.dealer),
            leaderName: seatName(deal.leader),
            yourHand: deal.you.cards.map(cardName),
            computerHand: deal.computer.cards.map(cardName),
            stockCount: deal.stock.count,
            discard: deal.discard.bottomToTop.map(cardName)
        )
    }

    static func load(seedText: String, keeping current: DealScene) -> (DealScene, String?) {
        let trimmed = seedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let seed = UInt64(trimmed) else {
            return (current, "Enter a whole number from 0.")
        }
        return (load(seed: seed), nil)
    }

    private static func seatName(_ seat: Seat) -> String {
        switch seat {
        case .you:
            return "You"
        case .computer:
            return "Computer"
        }
    }

    private static func cardName(_ card: Card) -> String {
        "\(rankName(card.rank)) of \(suitName(card.suit))"
    }

    private static func rankName(_ rank: Rank) -> String {
        switch rank {
        case .ace:
            return "ace"
        case .two:
            return "2"
        case .three:
            return "3"
        case .four:
            return "4"
        case .five:
            return "5"
        case .six:
            return "6"
        case .seven:
            return "7"
        case .eight:
            return "8"
        case .nine:
            return "9"
        case .ten:
            return "10"
        case .jack:
            return "jack"
        case .queen:
            return "queen"
        case .king:
            return "king"
        }
    }

    private static func suitName(_ suit: Suit) -> String {
        switch suit {
        case .clubs:
            return "clubs"
        case .diamonds:
            return "diamonds"
        case .hearts:
            return "hearts"
        case .spades:
            return "spades"
        }
    }
}
