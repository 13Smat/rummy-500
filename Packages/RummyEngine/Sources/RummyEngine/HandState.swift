public struct HandState: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        case awaitingDraw
        case mustUsePickedCard(Card)
        case mayMeldOrDiscard
        case handOver(Ending)
    }

    public enum Ending: Equatable, Sendable {
        case goneOut(Seat)
        case stockExhausted
    }

    public let you: Hand
    public let computer: Hand
    public let stock: Stock
    public let discard: DiscardPile
    public let melds: [Meld]
    public let turn: Seat
    public let phase: Phase
    public let seed: Seed
    public let rotation: DealRotation

    public static func deal(seed: Seed, rotation: DealRotation = .opening) -> HandState {
        let dealt = Deal.deal(seed: seed, rotation: rotation)
        return HandState(
            you: dealt.you,
            computer: dealt.computer,
            stock: dealt.stock,
            discard: dealt.discard,
            melds: [],
            turn: dealt.leader,
            phase: .awaitingDraw,
            seed: seed,
            rotation: rotation
        )
    }

    public func drawFromStock() -> Result<HandState, TurnRejection> {
        if let rejection = rejectionForDraw() {
            return .failure(rejection)
        }
        guard let top = stock.topToBottom.first else {
            return .failure(.stockIsEmpty)
        }
        let rest = Array(stock.topToBottom.dropFirst())
        let hand = cards(for: turn) + [top]
        return .success(
            updated(
                hand: hand,
                stock: Stock(topToBottom: rest),
                phase: .mayMeldOrDiscard
            )
        )
    }

    public func takeDiscard(_ card: Card) -> Result<HandState, TurnRejection> {
        if let rejection = rejectionForDraw() {
            return .failure(rejection)
        }
        guard let index = discard.bottomToTop.firstIndex(of: card) else {
            return .failure(.discardNotInPile)
        }
        let taken = Array(discard.bottomToTop[index...])
        let left = Array(discard.bottomToTop[..<index])
        let hand = cards(for: turn) + taken
        guard Self.canUse(card, in: hand, melds: melds, player: turn) else {
            return .failure(.discardCannotBeUsed)
        }
        return .success(
            updated(
                hand: hand,
                discard: DiscardPile(bottomToTop: left),
                phase: .mustUsePickedCard(card)
            )
        )
    }

    public func declineDiscardPile() -> Result<HandState, TurnRejection> {
        if let rejection = rejectionForDraw() {
            return .failure(rejection)
        }
        guard stock.topToBottom.isEmpty else {
            return .failure(.stockStillHasCards)
        }
        return .success(withPhase(.handOver(.stockExhausted)))
    }

    public func layDown(_ cards: [Card]) -> Result<HandState, TurnRejection> {
        if let rejection = rejectionForMeld() {
            return .failure(rejection)
        }
        if case .mustUsePickedCard(let owed) = phase, !cards.contains(owed) {
            return .failure(.pickedCardNotUsed)
        }
        guard let remaining = optionalRemoving(cards, from: self.cards(for: turn)) else {
            return .failure(.cardNotInHand)
        }
        switch Meld.layDown(cards, playedBy: turn) {
        case .failure(let reason):
            return .failure(.meldRejected(reason))
        case .success(let meld):
            return .success(
                updated(
                    hand: remaining,
                    melds: melds + [meld],
                    phase: phaseAfterPlaying(handIsEmpty: remaining.isEmpty)
                )
            )
        }
    }

    public func layOff(_ card: Card, onMeldAt index: Int) -> Result<HandState, TurnRejection> {
        if let rejection = rejectionForMeld() {
            return .failure(rejection)
        }
        if case .mustUsePickedCard(let owed) = phase, card != owed {
            return .failure(.pickedCardNotUsed)
        }
        guard cards(for: turn).contains(card) else {
            return .failure(.cardNotInHand)
        }
        guard melds.indices.contains(index) else {
            return .failure(.noSuchMeld)
        }
        switch melds[index].layOff(card, playedBy: turn) {
        case .failure(let reason):
            return .failure(.meldRejected(reason))
        case .success(let meld):
            var nextMelds = melds
            nextMelds[index] = meld
            let remaining = cards(for: turn).filter { $0 != card }
            return .success(
                updated(
                    hand: remaining,
                    melds: nextMelds,
                    phase: phaseAfterPlaying(handIsEmpty: remaining.isEmpty)
                )
            )
        }
    }

    public func discard(_ card: Card) -> Result<HandState, TurnRejection> {
        switch phase {
        case .handOver:
            return .failure(.handIsOver)
        case .awaitingDraw:
            return .failure(.stillDrawing)
        case .mustUsePickedCard(let owed):
            return .failure(.mustMeldOrLayOffPickedCard(owed))
        case .mayMeldOrDiscard:
            break
        }
        guard let remaining = optionalRemoving([card], from: cards(for: turn)) else {
            return .failure(.cardNotInHand)
        }
        let pile = DiscardPile(bottomToTop: discard.bottomToTop + [card])
        if remaining.isEmpty {
            return .success(
                updated(
                    hand: remaining,
                    discard: pile,
                    phase: .handOver(.goneOut(turn))
                )
            )
        }
        return .success(
            updated(
                hand: remaining,
                discard: pile,
                turn: turn.other,
                phase: .awaitingDraw
            )
        )
    }

    public var handResult: HandResult? {
        guard case .handOver = phase else {
            return nil
        }
        return HandResult(
            you: .init(table: tableCards(for: .you), hand: you.cards),
            computer: .init(table: tableCards(for: .computer), hand: computer.cards)
        )
    }

    public func cards(for seat: Seat) -> [Card] {
        switch seat {
        case .you:
            return you.cards
        case .computer:
            return computer.cards
        }
    }

    init(
        you: Hand,
        computer: Hand,
        stock: Stock,
        discard: DiscardPile,
        melds: [Meld],
        turn: Seat,
        phase: Phase,
        seed: Seed,
        rotation: DealRotation
    ) {
        let table = melds.flatMap(\.cards)
        let dealt = you.cards + computer.cards + stock.topToBottom + discard.bottomToTop + table
        assert(Set(dealt).count == dealt.count, "A hand lists each card once.")
        switch phase {
        case .handOver(.goneOut(let seat)):
            let held = seat == .you ? you.cards : computer.cards
            assert(held.isEmpty, "Going out leaves that hand empty.")
        case .handOver(.stockExhausted):
            assert(stock.topToBottom.isEmpty, "The stock is empty when the hand ends that way.")
        case .mustUsePickedCard(let card):
            let held = turn == .you ? you.cards : computer.cards
            assert(held.contains(card), "The picked card stays in the hand until it is played.")
        case .awaitingDraw, .mayMeldOrDiscard:
            let held = turn == .you ? you.cards : computer.cards
            assert(!held.isEmpty, "A turn still in progress holds at least one card.")
        }
        self.you = you
        self.computer = computer
        self.stock = stock
        self.discard = discard
        self.melds = melds
        self.turn = turn
        self.phase = phase
        self.seed = seed
        self.rotation = rotation
    }

    private func rejectionForDraw() -> TurnRejection? {
        switch phase {
        case .awaitingDraw:
            return nil
        case .handOver:
            return .handIsOver
        case .mustUsePickedCard(let owed):
            return .mustMeldOrLayOffPickedCard(owed)
        case .mayMeldOrDiscard:
            return .alreadyDrew
        }
    }

    private func rejectionForMeld() -> TurnRejection? {
        switch phase {
        case .mayMeldOrDiscard, .mustUsePickedCard:
            return nil
        case .handOver:
            return .handIsOver
        case .awaitingDraw:
            return .stillDrawing
        }
    }

    private func phaseAfterPlaying(handIsEmpty: Bool) -> Phase {
        if handIsEmpty {
            return .handOver(.goneOut(turn))
        }
        return .mayMeldOrDiscard
    }

    private func tableCards(for seat: Seat) -> [Card] {
        melds.flatMap { $0.cards(playedBy: seat) }
    }

    private func withPhase(_ phase: Phase) -> HandState {
        HandState(
            you: you,
            computer: computer,
            stock: stock,
            discard: discard,
            melds: melds,
            turn: turn,
            phase: phase,
            seed: seed,
            rotation: rotation
        )
    }

    private func updated(
        hand cards: [Card],
        stock: Stock? = nil,
        discard: DiscardPile? = nil,
        melds: [Meld]? = nil,
        turn nextTurn: Seat? = nil,
        phase: Phase
    ) -> HandState {
        HandState(
            you: Hand(cards: turn == .you ? cards : you.cards),
            computer: Hand(cards: turn == .computer ? cards : computer.cards),
            stock: stock ?? self.stock,
            discard: discard ?? self.discard,
            melds: melds ?? self.melds,
            turn: nextTurn ?? turn,
            phase: phase,
            seed: seed,
            rotation: rotation
        )
    }

    private static func canUse(
        _ card: Card,
        in hand: [Card],
        melds: [Meld],
        player: Seat
    ) -> Bool {
        CardUse.play(of: card, in: hand, melds: melds, player: player) != nil
    }
}

public enum TurnRejection: Equatable, Error, Sendable {
    case handIsOver
    case stillDrawing
    case alreadyDrew
    case stockIsEmpty
    case stockStillHasCards
    case discardNotInPile
    case discardCannotBeUsed
    case mustMeldOrLayOffPickedCard(Card)
    case pickedCardNotUsed
    case cardNotInHand
    case noSuchMeld
    case meldRejected(MeldRejection)
}

private func optionalRemoving(_ cards: [Card], from hand: [Card]) -> [Card]? {
    var remaining = hand
    for card in cards {
        guard let index = remaining.firstIndex(of: card) else {
            return nil
        }
        remaining.remove(at: index)
    }
    return remaining
}
