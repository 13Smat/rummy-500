enum CardPlay: Equatable {
    case layOff(Card, meldIndex: Int)
    case layDown([Card])

    var cards: [Card] {
        switch self {
        case .layOff(let card, _):
            return [card]
        case .layDown(let cards):
            return cards
        }
    }
}

enum CardUse {
    static func play(
        of card: Card,
        in hand: [Card],
        melds: [Meld],
        player: Seat
    ) -> CardPlay? {
        guard hand.contains(card) else {
            return nil
        }
        if let group = layDownGroup(of: card, in: hand, player: player) {
            return .layDown(group)
        }
        guard let index = melds.firstIndex(where: { meld in
            if case .success = meld.layOff(card, playedBy: player) {
                return true
            }
            return false
        }) else {
            return nil
        }
        return .layOff(card, meldIndex: index)
    }

    private static func layDownGroup(
        of card: Card,
        in hand: [Card],
        player: Seat
    ) -> [Card]? {
        var best: [Card]?
        func consider(_ cards: [Card]) {
            guard cards.contains(card) else {
                return
            }
            guard case .success = Meld.layDown(cards, playedBy: player) else {
                return
            }
            if let current = best {
                if ranksAhead(cards, current) {
                    best = cards
                }
            } else {
                best = cards
            }
        }

        let others = hand.filter { $0 != card }
        let sameRank = others.filter { $0.rank == card.rank }
        if (2...3).contains(sameRank.count) {
            consider([card] + sameRank)
        }
        let sameSuit = others.filter { $0.suit == card.suit }
        for aceHigh in [false, true] {
            let ordered = ([card] + sameSuit).sorted { lhs, rhs in
                rankOrder(lhs.rank, aceHigh: aceHigh) < rankOrder(rhs.rank, aceHigh: aceHigh)
            }
            guard let index = ordered.firstIndex(of: card) else {
                continue
            }
            var low = index
            var high = index
            while low > 0, isNext(ordered[low - 1], ordered[low], aceHigh: aceHigh) {
                low -= 1
            }
            while high + 1 < ordered.count, isNext(ordered[high], ordered[high + 1], aceHigh: aceHigh) {
                high += 1
            }
            let window = Array(ordered[low...high])
            let at = index - low
            guard window.count >= 3 else {
                continue
            }
            for start in 0...at {
                for end in at..<window.count where end - start >= 2 {
                    consider(Array(window[start...end]))
                }
            }
        }
        return best
    }

    private static func ranksAhead(_ cards: [Card], _ current: [Card]) -> Bool {
        let next = pointSum(cards)
        let previous = pointSum(current)
        if next != previous {
            return next > previous
        }
        if cards.count != current.count {
            return cards.count < current.count
        }
        return false
    }

    private static func isNext(_ earlier: Card, _ later: Card, aceHigh: Bool) -> Bool {
        rankOrder(later.rank, aceHigh: aceHigh) == rankOrder(earlier.rank, aceHigh: aceHigh) + 1
    }

    private static func rankOrder(_ rank: Rank, aceHigh: Bool) -> Int {
        if aceHigh && rank == .ace {
            return 14
        }
        return rank.rawValue
    }

    private static func pointSum(_ cards: [Card]) -> Int {
        cards.reduce(0) { $0 + $1.points }
    }
}
