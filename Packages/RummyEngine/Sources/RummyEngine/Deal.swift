public enum Seat: CaseIterable, Equatable, Hashable, Sendable {
    case you
    case computer

    var other: Seat {
        switch self {
        case .you:
            return .computer
        case .computer:
            return .you
        }
    }
}

public struct DealRotation: Equatable, Sendable {
    public let dealer: Seat

    public init(dealer: Seat) {
        self.dealer = dealer
    }

    public static let opening = DealRotation(dealer: .computer)

    public var leader: Seat {
        dealer.other
    }

    public func nextHand() -> DealRotation {
        DealRotation(dealer: dealer.other)
    }
}

public struct Deal: Equatable, Sendable {
    public let seed: Seed
    public let rotation: DealRotation
    public let you: Hand
    public let computer: Hand
    public let stock: Stock
    public let discard: DiscardPile

    public var dealer: Seat {
        rotation.dealer
    }

    public var leader: Seat {
        rotation.leader
    }

    public static func deal(seed: Seed, rotation: DealRotation = .opening) -> Deal {
        var generator = SeededGenerator(seed: seed)
        let shuffled = Deck.standard.shuffled(using: &generator).topToBottom
        var yours: [Card] = []
        var computers: [Card] = []
        yours.reserveCapacity(13)
        computers.reserveCapacity(13)
        for index in 0..<26 {
            let seat = index.isMultiple(of: 2) ? rotation.leader : rotation.dealer
            switch seat {
            case .you:
                yours.append(shuffled[index])
            case .computer:
                computers.append(shuffled[index])
            }
        }
        return Deal(
            seed: seed,
            rotation: rotation,
            you: Hand(cards: yours),
            computer: Hand(cards: computers),
            stock: Stock(topToBottom: Array(shuffled.dropFirst(27))),
            discard: DiscardPile(bottomToTop: [shuffled[26]])
        )
    }

    init(
        seed: Seed,
        rotation: DealRotation,
        you: Hand,
        computer: Hand,
        stock: Stock,
        discard: DiscardPile
    ) {
        let all = you.cards + computer.cards + stock.topToBottom + discard.bottomToTop
        assert(you.count == 13)
        assert(computer.count == 13)
        assert(stock.count == 25)
        assert(discard.count == 1)
        assert(all.count == 52)
        assert(Set(all) == Set(Deck.standard.topToBottom))
        self.seed = seed
        self.rotation = rotation
        self.you = you
        self.computer = computer
        self.stock = stock
        self.discard = discard
    }
}
