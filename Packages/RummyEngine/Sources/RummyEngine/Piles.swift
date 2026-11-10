public struct Hand: Equatable, Sendable {
    public let cards: [Card]

    public var count: Int {
        cards.count
    }

    init(cards: [Card]) {
        assert(Set(cards).count == cards.count)
        self.cards = cards
    }
}

public struct Stock: Equatable, Sendable {
    public let topToBottom: [Card]

    public var count: Int {
        topToBottom.count
    }

    init(topToBottom: [Card]) {
        assert(Set(topToBottom).count == topToBottom.count)
        self.topToBottom = topToBottom
    }
}

public struct DiscardPile: Equatable, Sendable {
    public let bottomToTop: [Card]

    public var count: Int {
        bottomToTop.count
    }

    public var top: Card? {
        bottomToTop.last
    }

    init(bottomToTop: [Card]) {
        assert(Set(bottomToTop).count == bottomToTop.count)
        self.bottomToTop = bottomToTop
    }
}
