public struct Deck: Equatable, Sendable {
    public let topToBottom: [Card]

    public static let standard = Deck(topToBottom: makeStandard())

    public func shuffled(using generator: inout SeededGenerator) -> Deck {
        var cards = topToBottom
        var index = cards.count - 1
        while index > 0 {
            let swapWith = Self.unbiasedIndex(below: index + 1, using: &generator)
            cards.swapAt(index, swapWith)
            index -= 1
        }
        return Deck(topToBottom: cards)
    }

    init(topToBottom: [Card]) {
        assert(topToBottom.count == 52)
        assert(Set(topToBottom).count == 52)
        self.topToBottom = topToBottom
    }

    private static func makeStandard() -> [Card] {
        var cards: [Card] = []
        cards.reserveCapacity(52)
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(Card(rank: rank, suit: suit))
            }
        }
        return cards
    }

    private static func unbiasedIndex(
        below upperBound: Int,
        using generator: inout SeededGenerator
    ) -> Int {
        let range = UInt64(upperBound)
        var draw = generator.next()
        let leftover = (UInt64.max % range &+ 1) % range
        while draw < leftover {
            draw = generator.next()
        }
        return Int(draw % range)
    }
}
