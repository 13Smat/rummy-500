public enum Rank: Int, CaseIterable, Hashable, Sendable {
    case ace = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13

    public var points: Int {
        switch self {
        case .ace:
            return 15
        case .jack, .queen, .king:
            return 10
        case .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten:
            return rawValue
        }
    }
}

public enum Suit: CaseIterable, Hashable, Sendable {
    case clubs
    case diamonds
    case hearts
    case spades
}

public struct Card: Hashable, Sendable {
    public let rank: Rank
    public let suit: Suit

    public init(rank: Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    public var points: Int {
        rank.points
    }
}
