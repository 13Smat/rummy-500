public struct SeatView: Equatable, Sendable {
    public let seat: Seat
    public let hand: [Card]
    public let discardBottomToTop: [Card]
    public let melds: [Meld]
    public let stockCount: Int
    public let phase: HandState.Phase
    public let yourScore: Int
    public let opponentScore: Int

    public init(hand: HandState, seat: Seat, yourScore: Int, opponentScore: Int) {
        self.seat = seat
        self.hand = hand.cards(for: seat)
        self.discardBottomToTop = hand.discard.bottomToTop
        self.melds = hand.melds
        self.stockCount = hand.stock.count
        self.phase = hand.phase
        self.yourScore = yourScore
        self.opponentScore = opponentScore
    }
}

public enum ComputerPlay: Equatable, Sendable {
    case drawFromStock
    case takeDiscard(Card)
    case declineDiscardPile
    case layDown([Card])
    case layOff(Card, meldIndex: Int)
    case discard(Card)
}

public struct ComputerStep: Equatable, Sendable {
    public let play: ComputerPlay
    public let state: HandState
}

public struct ComputerMoveError: Error, Equatable, Sendable {
    public let play: ComputerPlay
    public let rejection: TurnRejection
}

public struct ComputerRun: Equatable, Sendable, CustomStringConvertible {
    public let moves: Int
    public let discardPicks: Int
    public let deeperPicks: Int
    public let layoffs: Int

    public var description: String {
        "moves \(moves), discard picks \(discardPicks), deeper picks \(deeperPicks), layoffs \(layoffs)"
    }
}

public struct ComputerFailure: Error, Equatable, Sendable {
    public let seed: UInt64
    public let reason: Reason

    public enum Reason: Equatable, Sendable {
        case illegalMove(ComputerPlay, TurnRejection)
        case stateDidNotChange
        case handDidNotEnd
        case matchDidNotEnd
    }
}

public enum ComputerOpponent {
    public static func choose(_ view: SeatView) -> ComputerPlay {
        switch view.phase {
        case .handOver:
            preconditionFailure("The computer is asked to play after the hand is over.")
        case .awaitingDraw:
            return chooseDraw(view)
        case .mustUsePickedCard(let card):
            return playPicked(card, view)
        case .mayMeldOrDiscard:
            return meldOrDiscard(view)
        }
    }

    private static func chooseDraw(_ view: SeatView) -> ComputerPlay {
        if let card = bestDiscardPick(view) {
            return .takeDiscard(card)
        }
        if view.stockCount == 0 {
            return .declineDiscardPile
        }
        return .drawFromStock
    }

    private static func bestDiscardPick(_ view: SeatView) -> Card? {
        let pile = view.discardBottomToTop
        var best: (index: Int, card: Card, net: Int)?
        for index in pile.indices {
            let card = pile[index]
            let haul = Array(pile[index...])
            let hand = view.hand + haul
            guard let play = CardUse.play(
                of: card,
                in: hand,
                melds: view.melds,
                player: view.seat
            ) else {
                continue
            }
            let used = Set(play.cards)
            let gain = play.cards.reduce(0) { total, played in
                haul.contains(played) ? total + played.points : total
            }
            let remaining = hand.filter { !used.contains($0) }
            let kept = Set(
                Meld.largestGroups(in: remaining, playedBy: view.seat).flatMap(\.cards)
            )
            let unused = haul.reduce(0) { total, extra in
                if used.contains(extra) || kept.contains(extra) {
                    return total
                }
                return total + extra.points
            }
            guard unused == 0 || gain > unused else {
                continue
            }
            let net = gain - unused
            if let current = best {
                let betterNet = net > current.net
                let sameNetShallower = net == current.net && index > current.index
                if betterNet || sameNetShallower {
                    best = (index, card, net)
                }
            } else {
                best = (index, card, net)
            }
        }
        return best?.card
    }

    private static func playPicked(_ card: Card, _ view: SeatView) -> ComputerPlay {
        guard let play = CardUse.play(
            of: card,
            in: view.hand,
            melds: view.melds,
            player: view.seat
        ) else {
            return .layDown([card])
        }
        switch play {
        case .layDown(let cards):
            return .layDown(cards)
        case .layOff(let owed, let index):
            return .layOff(owed, meldIndex: index)
        }
    }

    private static func meldOrDiscard(_ view: SeatView) -> ComputerPlay {
        if let group = bestNewMeld(in: view.hand, player: view.seat) {
            return .layDown(group)
        }
        if let layoff = bestLayoff(in: view.hand, melds: view.melds, player: view.seat) {
            return .layOff(layoff.card, meldIndex: layoff.index)
        }
        return .discard(cardToDiscard(from: view.hand))
    }

    private static func bestNewMeld(in hand: [Card], player: Seat) -> [Card]? {
        Meld.largestGroups(in: hand, playedBy: player)
            .max { lhs, rhs in meldIsWorse(lhs, than: rhs) }?
            .cards
    }

    private static func meldIsWorse(_ lhs: Meld, than rhs: Meld) -> Bool {
        let left = pointSum(lhs.cards)
        let right = pointSum(rhs.cards)
        if left != right {
            return left < right
        }
        if lhs.cards.count != rhs.cards.count {
            return lhs.cards.count > rhs.cards.count
        }
        for (card, other) in zip(lhs.cards, rhs.cards) {
            if card.rank.rawValue != other.rank.rawValue {
                return card.rank.rawValue > other.rank.rawValue
            }
            let suit = suitIndex(card.suit)
            let otherSuit = suitIndex(other.suit)
            if suit != otherSuit {
                return suit > otherSuit
            }
        }
        return false
    }

    private static func bestLayoff(
        in hand: [Card],
        melds: [Meld],
        player: Seat
    ) -> (card: Card, index: Int)? {
        var best: (card: Card, index: Int)?
        for card in hand {
            for (index, meld) in melds.enumerated() {
                guard case .success = meld.layOff(card, playedBy: player) else {
                    continue
                }
                if let current = best, !layoffIsBetter(card, index, than: current) {
                    continue
                }
                best = (card, index)
            }
        }
        return best
    }

    private static func layoffIsBetter(
        _ card: Card,
        _ index: Int,
        than current: (card: Card, index: Int)
    ) -> Bool {
        if card.points != current.card.points {
            return card.points > current.card.points
        }
        let suit = suitIndex(card.suit)
        let currentSuit = suitIndex(current.card.suit)
        if suit != currentSuit {
            return suit < currentSuit
        }
        if card.rank.rawValue != current.card.rank.rawValue {
            return card.rank.rawValue < current.card.rank.rawValue
        }
        return index < current.index
    }

    private static func cardToDiscard(from hand: [Card]) -> Card {
        if hand.count == 1 {
            return hand[0]
        }
        let loose = hand.filter { !keepsCompany($0, in: hand) }
        let pool = loose.isEmpty ? hand : loose
        let keepHighCards = loose.isEmpty
        return pool.sorted { lhs, rhs in
            if lhs.points != rhs.points {
                return keepHighCards ? lhs.points < rhs.points : lhs.points > rhs.points
            }
            let suit = suitIndex(lhs.suit)
            let other = suitIndex(rhs.suit)
            if suit != other {
                return suit < other
            }
            return lhs.rank.rawValue < rhs.rank.rawValue
        }[0]
    }

    private static func keepsCompany(_ card: Card, in hand: [Card]) -> Bool {
        hand.contains { other in
            other != card && (other.rank == card.rank || isNeighbor(card, other))
        }
    }

    private static func isNeighbor(_ card: Card, _ other: Card) -> Bool {
        guard card.suit == other.suit else {
            return false
        }
        if abs(card.rank.rawValue - other.rank.rawValue) == 1 {
            return true
        }
        let aceAndKing = card.rank == .ace && other.rank == .king
            || card.rank == .king && other.rank == .ace
        return aceAndKing
    }

    private static func pointSum(_ cards: [Card]) -> Int {
        cards.reduce(0) { $0 + $1.points }
    }

    private static func suitIndex(_ suit: Suit) -> Int {
        Suit.allCases.firstIndex(of: suit) ?? 0
    }
}

public enum ComputerTable {
    public static let handMoveLimit = 200
    public static let matchHandLimit = 80

    public static func step(
        _ state: HandState,
        youScore: Int,
        computerScore: Int
    ) -> Result<ComputerStep, ComputerMoveError> {
        let seat = state.turn
        let view = SeatView(
            hand: state,
            seat: seat,
            yourScore: seat == .you ? youScore : computerScore,
            opponentScore: seat == .you ? computerScore : youScore
        )
        let play = ComputerOpponent.choose(view)
        switch apply(play, to: state) {
        case .failure(let rejection):
            return .failure(ComputerMoveError(play: play, rejection: rejection))
        case .success(let next):
            return .success(ComputerStep(play: play, state: next))
        }
    }

    public static func play(seed: UInt64) -> Result<HandState, ComputerFailure> {
        play(HandState.deal(seed: Seed(seed)), seed: seed).map(\.state)
    }

    public static func play(seeds: [UInt64]) -> Result<ComputerRun, ComputerFailure> {
        var moves = 0
        var discardPicks = 0
        var deeperPicks = 0
        var layoffs = 0
        for seed in seeds {
            switch tally(seed: seed) {
            case .failure(let failure):
                return .failure(failure)
            case .success(let run):
                moves += run.moves
                discardPicks += run.discardPicks
                deeperPicks += run.deeperPicks
                layoffs += run.layoffs
            }
        }
        return .success(
            ComputerRun(
                moves: moves,
                discardPicks: discardPicks,
                deeperPicks: deeperPicks,
                layoffs: layoffs
            )
        )
    }

    public static func playMatch(seed: UInt64) -> Result<Match, ComputerFailure> {
        var match = Match.opening
        var rotation = DealRotation.opening
        var handIndex = 0
        while match.conclusion == .playing {
            if handIndex >= matchHandLimit {
                return .failure(ComputerFailure(seed: seed, reason: .matchDidNotEnd))
            }
            let handSeed = seed &+ UInt64(handIndex)
            let dealt = HandState.deal(seed: Seed(handSeed), rotation: rotation)
            let played: FinishedHand
            switch play(dealt, seed: handSeed, youScore: match.you, computerScore: match.computer) {
            case .failure(let failure):
                return .failure(failure)
            case .success(let hand):
                played = hand
            }
            guard let result = played.state.handResult else {
                return .failure(ComputerFailure(seed: handSeed, reason: .handDidNotEnd))
            }
            match = match.record(result)
            rotation = rotation.nextHand()
            handIndex += 1
        }
        return .success(match)
    }

    private struct FinishedHand {
        let state: HandState
    }

    private static func tally(seed: UInt64) -> Result<ComputerRun, ComputerFailure> {
        var state = HandState.deal(seed: Seed(seed))
        var moves = 0
        var discardPicks = 0
        var deeperPicks = 0
        var layoffs = 0
        while true {
            if case .handOver = state.phase {
                return .success(
                    ComputerRun(
                        moves: moves,
                        discardPicks: discardPicks,
                        deeperPicks: deeperPicks,
                        layoffs: layoffs
                    )
                )
            }
            if moves >= handMoveLimit {
                return .failure(ComputerFailure(seed: seed, reason: .handDidNotEnd))
            }
            let top = state.discard.top
            switch step(state, youScore: 0, computerScore: 0) {
            case .failure(let error):
                return .failure(
                    ComputerFailure(
                        seed: seed,
                        reason: .illegalMove(error.play, error.rejection)
                    )
                )
            case .success(let played):
                if played.state == state {
                    return .failure(ComputerFailure(seed: seed, reason: .stateDidNotChange))
                }
                moves += 1
                if case .takeDiscard(let card) = played.play {
                    discardPicks += 1
                    if card != top {
                        deeperPicks += 1
                    }
                }
                if case .layOff = played.play {
                    layoffs += 1
                }
                state = played.state
            }
        }
    }

    private static func play(
        _ opening: HandState,
        seed: UInt64,
        youScore: Int = 0,
        computerScore: Int = 0
    ) -> Result<FinishedHand, ComputerFailure> {
        var state = opening
        var moves = 0
        while true {
            if case .handOver = state.phase {
                return .success(FinishedHand(state: state))
            }
            if moves >= handMoveLimit {
                return .failure(ComputerFailure(seed: seed, reason: .handDidNotEnd))
            }
            switch step(state, youScore: youScore, computerScore: computerScore) {
            case .failure(let error):
                return .failure(
                    ComputerFailure(
                        seed: seed,
                        reason: .illegalMove(error.play, error.rejection)
                    )
                )
            case .success(let played):
                if played.state == state {
                    return .failure(ComputerFailure(seed: seed, reason: .stateDidNotChange))
                }
                state = played.state
                moves += 1
            }
        }
    }

    private static func apply(
        _ play: ComputerPlay,
        to state: HandState
    ) -> Result<HandState, TurnRejection> {
        switch play {
        case .drawFromStock:
            return state.drawFromStock()
        case .takeDiscard(let card):
            return state.takeDiscard(card)
        case .declineDiscardPile:
            return state.declineDiscardPile()
        case .layDown(let cards):
            return state.layDown(cards)
        case .layOff(let card, let index):
            return state.layOff(card, onMeldAt: index)
        case .discard(let card):
            return state.discard(card)
        }
    }
}
