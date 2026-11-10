import RummyEngine

enum CardLabel {
    static func shortRank(_ rank: Rank) -> String {
        switch rank {
        case .ace:
            return "A"
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
            return "J"
        case .queen:
            return "Q"
        case .king:
            return "K"
        }
    }

    static func symbol(_ suit: Suit) -> String {
        switch suit {
        case .clubs:
            return "♣"
        case .diamonds:
            return "♦"
        case .hearts:
            return "♥"
        case .spades:
            return "♠"
        }
    }

    static func letter(_ suit: Suit) -> String {
        switch suit {
        case .clubs:
            return "C"
        case .diamonds:
            return "D"
        case .hearts:
            return "H"
        case .spades:
            return "S"
        }
    }

    static func spoken(_ card: Card) -> String {
        "\(spokenRank(card.rank)) of \(spokenSuit(card.suit))"
    }

    static func isRed(_ suit: Suit) -> Bool {
        switch suit {
        case .diamonds, .hearts:
            return true
        case .clubs, .spades:
            return false
        }
    }

    private static func spokenRank(_ rank: Rank) -> String {
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

    private static func spokenSuit(_ suit: Suit) -> String {
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
