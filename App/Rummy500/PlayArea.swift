import RummyEngine

enum StagedOffer: Equatable {
    case notReady
    case layDown
    case layOff(Int)
    case needsPickedCard
    case ambiguous
}

struct PlayArea: Equatable {
    var cards: [Card]

    func adding(_ card: Card) -> PlayArea {
        guard !cards.contains(card) else {
            return self
        }
        return PlayArea(cards: cards + [card])
    }

    func removing(_ card: Card) -> PlayArea {
        PlayArea(cards: cards.filter { $0 != card })
    }

    func offer(in hand: HandState) -> StagedOffer {
        guard !cards.isEmpty else {
            return .notReady
        }
        switch hand.layDown(cards) {
        case .success:
            return .layDown
        case .failure(.pickedCardNotUsed):
            return .needsPickedCard
        case .failure:
            break
        }
        var matches: [Int] = []
        for index in hand.melds.indices where laysOff(on: index, in: hand) {
            matches.append(index)
        }
        switch matches.count {
        case 1:
            return .layOff(matches[0])
        case 0:
            return .notReady
        default:
            return .ambiguous
        }
    }

    func applied(to hand: HandState) -> Result<HandState, TurnRejection> {
        switch offer(in: hand) {
        case .layDown:
            return hand.layDown(cards)
        case .layOff(let index):
            return layingOff(on: index, in: hand)
        case .notReady, .needsPickedCard, .ambiguous:
            return hand.layDown(cards)
        }
    }

    private func laysOff(on index: Int, in hand: HandState) -> Bool {
        if case .success = layingOff(on: index, in: hand) {
            return true
        }
        return false
    }

    private func layingOff(on index: Int, in hand: HandState) -> Result<HandState, TurnRejection> {
        var state = hand
        for card in cards {
            switch state.layOff(card, onMeldAt: index) {
            case .failure(let reason):
                return .failure(reason)
            case .success(let next):
                state = next
            }
        }
        return .success(state)
    }
}
