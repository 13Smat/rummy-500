import Foundation
import RummyEngine

struct ComputerScene: Equatable {
    let seed: UInt64
    let stockCount: Int
    let discard: [String]
    let yourHand: [String]
    let computerHand: [String]
    let melds: [String]
    let status: String
    let lastPlay: String
    let plays: [String]
    let yourHandScore: Int?
    let computerHandScore: Int?
    let yourMatchTotal: Int
    let computerMatchTotal: Int
    let matchStatus: String
    let handsPlayed: Int
    let canStep: Bool

    static func load(seed: UInt64) -> ComputerScene {
        let dealt = HandState.deal(seed: Seed(seed))
        return ComputerScene(
            seed: seed,
            handSeed: seed,
            rotation: .opening,
            match: .opening,
            state: dealt,
            plays: [],
            lastPlay: "Dealt the hand",
            halted: false
        )
    }

    static func load(seedText: String, keeping current: ComputerScene) -> (ComputerScene, String?) {
        let trimmed = seedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let seed = UInt64(trimmed) else {
            return (current, "Enter a whole number from 0.")
        }
        return (load(seed: seed), nil)
    }

    func steppingForward() -> ComputerScene {
        guard canStep else {
            return self
        }
        if case .handOver = state.phase {
            return advancePastHand()
        }
        switch ComputerTable.step(state, youScore: match.you, computerScore: match.computer) {
        case .failure(let error):
            return stopped("Illegal move: \(playLine(error.play, seat: state.turn))")
        case .success(let stepped):
            let line = playLine(stepped.play, seat: state.turn)
            return ComputerScene(
                seed: seed,
                handSeed: handSeed,
                rotation: rotation,
                match: match,
                state: stepped.state,
                plays: plays + [line],
                lastPlay: line,
                halted: false
            )
        }
    }

    func autoplaying() -> ComputerScene {
        var scene = self
        var steps = 0
        while scene.canStep && steps < 20_000 {
            scene = scene.steppingForward()
            steps += 1
        }
        return scene
    }

    private let handSeed: UInt64
    private let rotation: DealRotation
    private let match: Match
    private let state: HandState

    private init(
        seed: UInt64,
        handSeed: UInt64,
        rotation: DealRotation,
        match: Match,
        state: HandState,
        plays: [String],
        lastPlay: String,
        halted: Bool
    ) {
        self.seed = seed
        self.handSeed = handSeed
        self.rotation = rotation
        self.match = match
        self.state = state
        self.plays = plays
        self.lastPlay = lastPlay
        stockCount = state.stock.count
        discard = state.discard.bottomToTop.map(cardName)
        yourHand = state.you.cards.map(cardName)
        computerHand = state.computer.cards.map(cardName)
        melds = state.melds.map(meldLine)
        status = statusLine(state)
        if let result = state.handResult {
            yourHandScore = result.score.you
            computerHandScore = result.score.computer
        } else {
            yourHandScore = nil
            computerHandScore = nil
        }
        yourMatchTotal = match.you
        computerMatchTotal = match.computer
        matchStatus = matchStatusLine(match)
        handsPlayed = match.hands.count
        if halted {
            canStep = false
        } else if case .won = match.conclusion {
            canStep = false
        } else {
            canStep = true
        }
    }

    private func advancePastHand() -> ComputerScene {
        guard let result = state.handResult else {
            return stopped("The hand ended without a score")
        }
        let recorded = match.record(result)
        if case .won = recorded.conclusion {
            return ComputerScene(
                seed: seed,
                handSeed: handSeed,
                rotation: rotation,
                match: recorded,
                state: state,
                plays: plays,
                lastPlay: lastPlay,
                halted: false
            )
        }
        let nextRotation = rotation.nextHand()
        let nextSeed = handSeed &+ 1
        let dealt = HandState.deal(seed: Seed(nextSeed), rotation: nextRotation)
        return ComputerScene(
            seed: seed,
            handSeed: nextSeed,
            rotation: nextRotation,
            match: recorded,
            state: dealt,
            plays: [],
            lastPlay: "Dealt the next hand",
            halted: false
        )
    }

    private func stopped(_ line: String) -> ComputerScene {
        ComputerScene(
            seed: seed,
            handSeed: handSeed,
            rotation: rotation,
            match: match,
            state: state,
            plays: plays + [line],
            lastPlay: line,
            halted: true
        )
    }
}

private func playLine(_ play: ComputerPlay, seat: Seat) -> String {
    let who = seat == .you ? "You" : "Computer"
    switch play {
    case .drawFromStock:
        return "\(who) drew from the stock"
    case .takeDiscard(let card):
        return "\(who) took the \(cardName(card)) from the discard"
    case .declineDiscardPile:
        return "\(who) left the discard pile"
    case .layDown(let cards):
        let names = cards.map(cardName).joined(separator: ", ")
        return "\(who) laid down \(names)"
    case .layOff(let card, _):
        return "\(who) laid off the \(cardName(card))"
    case .discard(let card):
        return "\(who) discarded the \(cardName(card))"
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

private func matchStatusLine(_ match: Match) -> String {
    switch match.conclusion {
    case .playing:
        return "Playing"
    case .won(.you):
        return "You win"
    case .won(.computer):
        return "Computer wins"
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
    seat == .you ? "You" : "Computer"
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
