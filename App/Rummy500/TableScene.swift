import RummyEngine

enum TablePreset: CaseIterable, Equatable, Identifiable {
    case freshDeal
    case midHand
    case longDiscard

    var id: Self { self }

    var title: String {
        switch self {
        case .freshDeal:
            return "Fresh deal"
        case .midHand:
            return "Mid-hand"
        case .longDiscard:
            return "Long discard"
        }
    }
}

struct TableMeldCard: Equatable {
    let card: Card
    let playedBy: Seat
}

struct TableMeld: Equatable, Identifiable {
    let id: Int
    let kind: Meld.Kind
    let laidDownBy: Seat
    let cards: [TableMeldCard]

    var kindLabel: String {
        kind == .set ? "Set" : "Run"
    }

    fileprivate init(_ meld: Meld, id: Int) {
        self.id = id
        kind = meld.kind
        cards = meld.played.map { TableMeldCard(card: $0.card, playedBy: $0.player) }
        let yours = meld.cards(playedBy: .you).count
        let computers = meld.cards(playedBy: .computer).count
        if yours > computers {
            laidDownBy = .you
        } else if computers > yours {
            laidDownBy = .computer
        } else {
            laidDownBy = meld.played[0].player
        }
    }
}

struct TableScene: Equatable {
    let preset: TablePreset
    let yourHand: [Card]
    let opponentCount: Int
    let stockCount: Int
    let discard: [Card]
    let melds: [TableMeld]
    let yourScore: Int
    let computerScore: Int
    let turnLabel: String
    let phaseLabel: String

    var cardCount: Int {
        yourHand.count
            + opponentCount
            + stockCount
            + discard.count
            + melds.reduce(0) { $0 + $1.cards.count }
    }

    func cards(playedBy seat: Seat) -> [Card] {
        melds.flatMap { meld in
            meld.cards.compactMap { entry in
                entry.playedBy == seat ? entry.card : nil
            }
        }
    }

    func melds(laidDownBy seat: Seat) -> [TableMeld] {
        melds.filter { $0.laidDownBy == seat }
    }

    static func load(_ preset: TablePreset) -> TableScene {
        let hand = TablePresets.hand(preset)
        return reading(
            preset: preset,
            hand: hand,
            match: TablePresets.match(preset),
            yourHand: sortedHand(hand.you.cards)
        )
    }

    static func reading(
        preset: TablePreset,
        hand: HandState,
        match: Match,
        yourHand: [Card]
    ) -> TableScene {
        TableScene(preset: preset, hand: hand, match: match, yourHand: yourHand)
    }

    static func sortedHand(_ cards: [Card]) -> [Card] {
        cards.sorted { lhs, rhs in
            let leftSuit = Suit.allCases.firstIndex(of: lhs.suit) ?? 0
            let rightSuit = Suit.allCases.firstIndex(of: rhs.suit) ?? 0
            if leftSuit != rightSuit {
                return leftSuit < rightSuit
            }
            return lhs.rank.rawValue < rhs.rank.rawValue
        }
    }

    private init(preset: TablePreset, hand: HandState, match: Match, yourHand: [Card]) {
        self.preset = preset
        self.yourHand = yourHand
        opponentCount = hand.computer.count
        stockCount = hand.stock.count
        discard = hand.discard.bottomToTop
        melds = hand.melds.enumerated().map { TableMeld($0.element, id: $0.offset) }
        yourScore = match.you
        computerScore = match.computer
        turnLabel = Self.turnLabel(for: hand)
        phaseLabel = Self.phaseLabel(for: hand)
    }

    private static func turnLabel(for hand: HandState) -> String {
        if case .handOver = hand.phase {
            return "Hand over"
        }
        return hand.turn == .you ? "Your turn" : "Computer's turn"
    }

    private static func phaseLabel(for hand: HandState) -> String {
        switch hand.phase {
        case .awaitingDraw:
            return "Draw a card"
        case .mayMeldOrDiscard:
            return "Meld or discard"
        case .mustUsePickedCard(let card):
            return "Play the \(CardLabel.spoken(card))"
        case .handOver(.goneOut(.you)):
            return "You went out"
        case .handOver(.goneOut(.computer)):
            return "Computer went out"
        case .handOver(.stockExhausted):
            return "The stock is empty"
        }
    }
}

enum TablePlay: Equatable {
    case drawFromStock
    case layDown([Card])
    case layOff(Card, Int)
    case discard(Card)
    case takeDiscard(Card)
}

enum TablePresets {
    static func hand(_ preset: TablePreset) -> HandState {
        switch preset {
        case .freshDeal:
            return HandState.deal(seed: Seed(0))
        case .midHand:
            return play(seed: midSeed, moves: midMoves)
        case .longDiscard:
            return play(seed: longSeed, moves: longMoves)
        }
    }

    static func match(_ preset: TablePreset) -> Match {
        switch preset {
        case .freshDeal:
            return .opening
        case .midHand:
            return Match.opening.record(earlierHand)
        case .longDiscard:
            return Match.opening.record(earlierHand).record(laterHand)
        }
    }

    static func play(seed: UInt64, moves: [TablePlay]) -> HandState {
        var state = HandState.deal(seed: Seed(seed))
        for move in moves {
            let result: Result<HandState, TurnRejection>
            switch move {
            case .drawFromStock:
                result = state.drawFromStock()
            case .layDown(let cards):
                result = state.layDown(cards)
            case .layOff(let card, let index):
                result = state.layOff(card, onMeldAt: index)
            case .discard(let card):
                result = state.discard(card)
            case .takeDiscard(let card):
                result = state.takeDiscard(card)
            }
            switch result {
            case .success(let next):
                state = next
            case .failure:
                preconditionFailure("A table preset played a move the engine refused.")
            }
        }
        return state
    }

    private static let earlierHand = HandResult(
        you: .init(table: [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .two, suit: .hearts),
            Card(rank: .three, suit: .hearts),
        ]),
        computer: .init(hand: [
            Card(rank: .ace, suit: .spades),
        ])
    )

    private static let laterHand = HandResult(
        you: .init(table: [
            Card(rank: .ten, suit: .clubs),
        ]),
        computer: .init(
            table: [Card(rank: .five, suit: .diamonds)],
            hand: [Card(rank: .ace, suit: .clubs)]
        )
    )

    private static let midSeed: UInt64 = 54
    private static let midMoves: [TablePlay] = [
        .drawFromStock,
        .layDown([
            Card(rank: .ace, suit: .diamonds),
            Card(rank: .two, suit: .diamonds),
            Card(rank: .three, suit: .diamonds),
        ]),
        .layDown([
            Card(rank: .five, suit: .clubs),
            Card(rank: .five, suit: .diamonds),
            Card(rank: .five, suit: .spades),
        ]),
        .layDown([
            Card(rank: .six, suit: .diamonds),
            Card(rank: .six, suit: .hearts),
            Card(rank: .six, suit: .spades),
        ]),
        .discard(Card(rank: .two, suit: .hearts)),
        .drawFromStock,
        .layDown([
            Card(rank: .queen, suit: .clubs),
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .queen, suit: .hearts),
        ]),
        .layOff(Card(rank: .four, suit: .diamonds), 0),
        .layOff(Card(rank: .five, suit: .hearts), 1),
    ]

    private static let longSeed: UInt64 = 0
    private static let longMoves: [TablePlay] = [
        .drawFromStock,
        .discard(Card(rank: .eight, suit: .spades)),
        .drawFromStock,
        .discard(Card(rank: .jack, suit: .hearts)),
        .drawFromStock,
        .discard(Card(rank: .nine, suit: .clubs)),
        .drawFromStock,
        .discard(Card(rank: .two, suit: .spades)),
        .drawFromStock,
        .discard(Card(rank: .two, suit: .diamonds)),
        .drawFromStock,
        .discard(Card(rank: .queen, suit: .diamonds)),
        .drawFromStock,
        .discard(Card(rank: .six, suit: .spades)),
        .drawFromStock,
        .discard(Card(rank: .ten, suit: .clubs)),
        .drawFromStock,
        .discard(Card(rank: .three, suit: .diamonds)),
        .drawFromStock,
        .discard(Card(rank: .ace, suit: .clubs)),
        .drawFromStock,
        .discard(Card(rank: .jack, suit: .clubs)),
        .drawFromStock,
        .discard(Card(rank: .seven, suit: .clubs)),
        .drawFromStock,
        .discard(Card(rank: .nine, suit: .hearts)),
        .drawFromStock,
        .discard(Card(rank: .eight, suit: .clubs)),
        .drawFromStock,
        .discard(Card(rank: .queen, suit: .spades)),
        .drawFromStock,
        .discard(Card(rank: .king, suit: .hearts)),
        .takeDiscard(Card(rank: .three, suit: .diamonds)),
    ]

    static func handBeforeLongPick() -> HandState {
        play(seed: longSeed, moves: Array(longMoves.dropLast()))
    }
}
