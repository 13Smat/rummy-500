import RummyEngine

struct TurnScene: Equatable {
    let stockCount: Int
    let discard: [String]
    let yourHand: [String]
    let computerHand: [String]
    let melds: [String]
    let status: String
    let yourScore: Int?
    let computerScore: Int?
    let yourMatchTotal: Int?
    let computerMatchTotal: Int?
    let step: Int
    let stepCount: Int

    var hasAnotherStep: Bool {
        step + 1 < stepCount
    }

    static let opening = TurnScene(step: 0)

    func steppingForward() -> TurnScene {
        guard hasAnotherStep else {
            return self
        }
        return TurnScene(step: step + 1)
    }

    private init(step: Int) {
        let trace = HandState.scriptedPlay()
        let state = trace[step]
        stockCount = state.stock.count
        discard = state.discard.bottomToTop.map(CardLabel.spoken)
        yourHand = state.you.cards.map(CardLabel.spoken)
        computerHand = state.computer.cards.map(CardLabel.spoken)
        melds = state.melds.map(meldLine)
        status = statusLine(state)
        if let result = state.handResult {
            let match = Match.opening.record(result)
            yourScore = result.score.you
            computerScore = result.score.computer
            yourMatchTotal = match.you
            computerMatchTotal = match.computer
        } else {
            yourScore = nil
            computerScore = nil
            yourMatchTotal = nil
            computerMatchTotal = nil
        }
        self.step = step
        stepCount = trace.count
    }
}

private func statusLine(_ state: HandState) -> String {
    switch state.phase {
    case .awaitingDraw:
        if state.stock.count == 0 {
            return state.turn == .you
                ? "Your turn, and the stock is empty"
                : "Computer's turn, and the stock is empty"
        }
        return state.turn == .you ? "Your turn to draw" : "Computer's turn to draw"
    case .mustUsePickedCard(let card):
        let name = CardLabel.spoken(card)
        return state.turn == .you ? "You must play the \(name)" : "Computer must play the \(name)"
    case .mayMeldOrDiscard:
        return state.turn == .you ? "Your turn to meld or discard" : "Computer's turn to meld or discard"
    case .handOver(.goneOut(.you)):
        return "You went out"
    case .handOver(.goneOut(.computer)):
        return "Computer went out"
    case .handOver(.stockExhausted):
        return "The stock is empty"
    }
}

private func meldLine(_ meld: Meld) -> String {
    let kind = meld.kind == .set ? "Set" : "Run"
    let names = meld.played.map { played in
        "\(CardLabel.spoken(played.card)) (\(seatName(played.player)))"
    }
    return "\(kind): \(names.joined(separator: ", "))"
}

private func seatName(_ seat: Seat) -> String {
    switch seat {
    case .you:
        return "You"
    case .computer:
        return "Computer"
    }
}

