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
        discard = state.discard.bottomToTop.map(cardName)
        yourHand = state.you.cards.map(cardName)
        computerHand = state.computer.cards.map(cardName)
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
        let name = cardName(card)
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
        "\(cardName(played.card)) (\(seatName(played.player)))"
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

private func cardName(_ card: Card) -> String {
    "\(rankName(card.rank)) of \(suitName(card.suit))"
}

private func rankName(_ rank: Rank) -> String {
    switch rank {
    case .ace:
        return "ace"
    case .two:
        return "2"
    case .three:
        return "3"
    case .four:
        return "4"
    case .five:
        return "5"
    case .six:
        return "6"
    case .seven:
        return "7"
    case .eight:
        return "8"
    case .nine:
        return "9"
    case .ten:
        return "10"
    case .jack:
        return "jack"
    case .queen:
        return "queen"
    case .king:
        return "king"
    }
}

private func suitName(_ suit: Suit) -> String {
    switch suit {
    case .clubs:
        return "clubs"
    case .diamonds:
        return "diamonds"
    case .hearts:
        return "hearts"
    case .spades:
        return "spades"
    }
}
