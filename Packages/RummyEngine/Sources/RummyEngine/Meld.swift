public struct PlayedCard: Equatable, Hashable, Sendable {
    public let card: Card
    public let player: Seat
}

public enum MeldRejection: Equatable, Error, Sendable {
    case needsThreeCards
    case fiveOfAKind
    case duplicateCard
    case mixedSuit
    case wrapsAround
    case notInSequence
    case doesNotFit
}

public struct Meld: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case set
        case run
    }

    public let kind: Kind
    public let played: [PlayedCard]

    public var cards: [Card] {
        played.map(\.card)
    }

    public func cards(playedBy player: Seat) -> [Card] {
        played.compactMap { entry in
            entry.player == player ? entry.card : nil
        }
    }

    public static func layDown(
        _ cards: [Card],
        playedBy player: Seat
    ) -> Result<Meld, MeldRejection> {
        arrange(cards).map { arrangement in
            Meld(
                kind: arrangement.kind,
                played: arrangement.cards.map { PlayedCard(card: $0, player: player) }
            )
        }
    }

    public func layOff(
        _ card: Card,
        playedBy player: Seat
    ) -> Result<Meld, MeldRejection> {
        if played.contains(where: { $0.card == card }) {
            return .failure(.duplicateCard)
        }
        switch arrange(cards + [card]) {
        case .failure(let reason):
            return .failure(reasonForLayoff(reason, card: card))
        case .success(let arrangement):
            var owners = Dictionary(uniqueKeysWithValues: played.map { ($0.card, $0.player) })
            owners[card] = player
            var next: [PlayedCard] = []
            next.reserveCapacity(arrangement.cards.count)
            for ordered in arrangement.cards {
                let owner: Seat
                if let existing = owners[ordered] {
                    owner = existing
                } else {
                    preconditionFailure("layoff lost a card")
                }
                next.append(PlayedCard(card: ordered, player: owner))
            }
            return .success(Meld(kind: arrangement.kind, played: next))
        }
    }

    public static func largestGroups(
        in cards: [Card],
        playedBy player: Seat
    ) -> [Meld] {
        let unique = uniqueCards(cards)
        var groups: [Meld] = []
        for rank in Rank.allCases {
            let matching = unique.filter { $0.rank == rank }
            if case .success(let meld) = layDown(matching, playedBy: player) {
                groups.append(meld)
            }
        }
        for suit in Suit.allCases {
            let matching = unique.filter { $0.suit == suit }
            groups.append(contentsOf: longestRuns(in: matching, playedBy: player))
        }
        return groups
    }

    private init(kind: Kind, played: [PlayedCard]) {
        assert(played.count >= 3)
        assert(Set(played.map(\.card)).count == played.count)
        self.kind = kind
        self.played = played
    }

    private func reasonForLayoff(_ reason: MeldRejection, card: Card) -> MeldRejection {
        switch (kind, reason) {
        case (.set, .mixedSuit) where card.rank != played[0].card.rank:
            return .doesNotFit
        case (.run, .notInSequence):
            return .doesNotFit
        default:
            return reason
        }
    }
}

private struct MeldArrangement {
    let kind: Meld.Kind
    let cards: [Card]
}

private func arrange(_ cards: [Card]) -> Result<MeldArrangement, MeldRejection> {
    if cards.count < 3 {
        return .failure(.needsThreeCards)
    }
    if Set(cards).count != cards.count {
        if cards.count >= 5, cards.allSatisfy({ $0.rank == cards[0].rank }) {
            return .failure(.fiveOfAKind)
        }
        return .failure(.duplicateCard)
    }
    if cards.allSatisfy({ $0.rank == cards[0].rank }) {
        if cards.count > 4 {
            return .failure(.fiveOfAKind)
        }
        let sorted = cards.sorted { suitIndex($0.suit) < suitIndex($1.suit) }
        return .success(MeldArrangement(kind: .set, cards: sorted))
    }
    if Set(cards.map(\.suit)).count != 1 {
        return .failure(.mixedSuit)
    }
    return arrangeRun(cards)
}

private func arrangeRun(_ cards: [Card]) -> Result<MeldArrangement, MeldRejection> {
    let low = cards.sorted { lowPosition($0.rank) < lowPosition($1.rank) }
    let high = cards.sorted { highPosition($0.rank) < highPosition($1.rank) }
    if isContiguous(low, position: lowPosition) {
        return .success(MeldArrangement(kind: .run, cards: low))
    }
    if isContiguous(high, position: highPosition) {
        return .success(MeldArrangement(kind: .run, cards: high))
    }
    if ranksWrapTheCorner(cards) {
        return .failure(.wrapsAround)
    }
    return .failure(.notInSequence)
}

private func longestRuns(in cards: [Card], playedBy player: Seat) -> [Meld] {
    var candidates: [Set<Card>] = []
    for aceHigh in [false, true] {
        let sorted = cards.sorted { lhs, rhs in
            position(lhs.rank, aceHigh: aceHigh) < position(rhs.rank, aceHigh: aceHigh)
        }
        var current: [Card] = []
        func close() {
            defer { current = [] }
            if current.count >= 3 {
                candidates.append(Set(current))
            }
        }
        for card in sorted {
            if let last = current.last {
                let previous = position(last.rank, aceHigh: aceHigh)
                let next = position(card.rank, aceHigh: aceHigh)
                if next != previous + 1 {
                    close()
                }
            }
            current.append(card)
        }
        close()
    }
    var seen: Set<Set<Card>> = []
    var runs: [Meld] = []
    for group in candidates {
        let covered = candidates.contains { other in
            other.count > group.count && group.isSubset(of: other)
        }
        guard !covered, seen.insert(group).inserted else {
            continue
        }
        if case .success(let meld) = Meld.layDown(Array(group), playedBy: player) {
            runs.append(meld)
        }
    }
    return runs
}

private func uniqueCards(_ cards: [Card]) -> [Card] {
    var seen: Set<Card> = []
    var unique: [Card] = []
    for card in cards where seen.insert(card).inserted {
        unique.append(card)
    }
    return unique
}

private func isContiguous(_ cards: [Card], position: (Rank) -> Int) -> Bool {
    for index in 1..<cards.count {
        let previous = position(cards[index - 1].rank)
        let next = position(cards[index].rank)
        if next != previous + 1 {
            return false
        }
    }
    return true
}

private func ranksWrapTheCorner(_ cards: [Card]) -> Bool {
    let values = cards.map(\.rank.rawValue).sorted()
    guard values.count >= 3 else {
        return false
    }
    var gaps: [Int] = []
    gaps.reserveCapacity(values.count)
    for index in 1..<values.count {
        gaps.append(values[index] - values[index - 1])
    }
    gaps.append(values[0] + 13 - values[values.count - 1])
    let oversized = gaps.filter { $0 > 1 }
    if oversized.isEmpty {
        return values.count == 13
    }
    return oversized.count == 1
}

private func position(_ rank: Rank, aceHigh: Bool) -> Int {
    aceHigh ? highPosition(rank) : lowPosition(rank)
}

private func lowPosition(_ rank: Rank) -> Int {
    rank.rawValue
}

private func highPosition(_ rank: Rank) -> Int {
    rank == .ace ? 14 : rank.rawValue
}

private func suitIndex(_ suit: Suit) -> Int {
    Suit.allCases.firstIndex(of: suit) ?? 0
}
