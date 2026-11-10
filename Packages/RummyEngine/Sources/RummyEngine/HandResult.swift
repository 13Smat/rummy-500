public struct HandScore: Equatable, Sendable {
    public let you: Int
    public let computer: Int

    init(you: Int, computer: Int) {
        self.you = you
        self.computer = computer
    }
}

public struct HandResult: Equatable, Sendable {
    public struct Cards: Equatable, Sendable {
        public let table: [Card]
        public let hand: [Card]

        public init(table: [Card] = [], hand: [Card] = []) {
            self.table = table
            self.hand = hand
        }
    }

    public let you: Cards
    public let computer: Cards

    public init(you: Cards = .init(), computer: Cards = .init()) {
        let dealt = you.table + you.hand + computer.table + computer.hand
        assert(Set(dealt).count == dealt.count, "A finished hand lists each card once.")
        self.you = you
        self.computer = computer
    }

    public var score: HandScore {
        HandScore(
            you: Self.points(table: you.table, hand: you.hand),
            computer: Self.points(table: computer.table, hand: computer.hand)
        )
    }

    private static func points(table: [Card], hand: [Card]) -> Int {
        table.reduce(0) { $0 + $1.points } - hand.reduce(0) { $0 + $1.points }
    }
}
