import Foundation
import RummyEngine

struct TableSession: Equatable {
    private(set) var hand: HandState
    private(set) var match: Match
    private(set) var order: [Card]
    private(set) var playArea: PlayArea
    private(set) var notice: String?
    private(set) var computerLine: String?
    private(set) var menuPreset: TablePreset?
    private(set) var computerPending: Bool
    private(set) var beat: Int
    private(set) var handOrder: HandOrder
    let playsLive: Bool
    private var recordedThisHand: Bool

    var scene: TableScene {
        .reading(
            preset: menuPreset ?? .freshDeal,
            hand: hand,
            match: match,
            yourHand: order
        )
    }

    var owedCard: Card? {
        guard hand.turn == .you, case .mustUsePickedCard(let card) = hand.phase else {
            return nil
        }
        return card
    }

    var mustUseText: String? {
        guard let owedCard else {
            return nil
        }
        return "Play the \(CardLabel.spoken(owedCard)) before you do anything else."
    }

    var playIsEnabled: Bool {
        guard hand.turn == .you, hand.handResult == nil else {
            return false
        }
        switch playArea.offer(in: hand) {
        case .layDown, .layOff:
            return true
        case .notReady, .needsPickedCard, .ambiguous:
            return false
        }
    }

    var playRefusal: String? {
        guard hand.turn == .you, case .needsPickedCard = playArea.offer(in: hand) else {
            return nil
        }
        return TurnWords.saying(.pickedCardNotUsed)
    }

    var handResultText: String? {
        guard let score = hand.handResult?.score else {
            return nil
        }
        return "This hand: you \(score.you), computer \(score.computer)."
    }

    var nextHandTitle: String {
        if case .won = match.conclusion {
            return "Play again"
        }
        return "Deal the next hand"
    }

    var showsNextHand: Bool {
        hand.handResult != nil
    }

    var cue: TableCue {
        if hand.handResult != nil {
            return .handOver
        }
        guard hand.turn == .you else {
            return .none
        }
        switch hand.phase {
        case .awaitingDraw:
            return hand.stock.count == 0 ? .pass : .draw
        case .mayMeldOrDiscard:
            return .discard
        case .mustUsePickedCard(_), .handOver(_):
            return .none
        }
    }

    var stockActionTitle: String {
        cue == .pass ? "Leave the pile" : "Draw"
    }

    var turnActionTitle: String? {
        cue == .handOver ? nextHandTitle : nil
    }

    static func opening(seed: UInt64, playsLive: Bool) -> TableSession {
        TableSession(
            hand: HandState.deal(seed: Seed(seed)),
            match: .opening,
            playsLive: playsLive,
            menuPreset: .freshDeal
        )
    }

    init(preset: TablePreset, playsLive: Bool) {
        self.init(
            hand: TablePresets.hand(preset),
            match: TablePresets.match(preset),
            playsLive: playsLive,
            menuPreset: preset
        )
    }

    init(
        hand: HandState,
        match: Match,
        playsLive: Bool,
        menuPreset: TablePreset? = nil
    ) {
        self.hand = hand
        self.match = match
        self.playsLive = playsLive
        self.menuPreset = menuPreset
        order = TableScene.sortedHand(hand.you.cards)
        playArea = PlayArea(cards: [])
        notice = nil
        computerLine = nil
        recordedThisHand = false
        beat = 0
        handOrder = .suit
        computerPending = false
        if playsLive, hand.turn == .computer, hand.handResult == nil {
            computerPending = true
            beat = 1
        }
    }

    func drawFromStock() -> TableSession {
        receive(.drawStock)
    }

    func takeDiscard(_ card: Card) -> TableSession {
        receive(.takeDiscard(.discard(card)))
    }

    func tapStock() -> TableSession {
        if cue == .pass {
            return declining()
        }
        return receive(.drawStock)
    }

    func tapTurn() -> TableSession {
        guard cue == .handOver else {
            return self
        }
        return dealNextHand()
    }

    func stage(_ card: Card) -> TableSession {
        receive(.stage(.hand(card)))
    }

    func unstage(_ card: Card) -> TableSession {
        receive(.placeInHand(.playArea(card), at: order.count))
    }

    func receive(_ drop: CardDrop) -> TableSession {
        if let blocked = gate() {
            return blocked
        }
        switch effect(drop) {
        case .hand(let next):
            return applying(.success(next))
        case .arranged(let order, let playArea):
            var copy = self
            copy.order = order
            copy.playArea = playArea
            copy.notice = nil
            return copy
        case .refuse(let text):
            return refusing(text)
        case .ignore:
            return self
        }
    }

    func accepts(_ drop: CardDrop) -> Bool {
        guard hand.turn == .you, hand.handResult == nil else {
            return false
        }
        switch effect(drop) {
        case .hand, .arranged:
            return true
        case .refuse, .ignore:
            return false
        }
    }

    func nudge(_ card: Card, by delta: Int) -> TableSession {
        guard let index = order.firstIndex(of: card) else {
            return self
        }
        let target = index + delta
        guard order.indices.contains(target) else {
            return self
        }
        return receive(.placeInHand(.hand(card), at: target))
    }

    func clearPlayArea() -> TableSession {
        if let blocked = gate() {
            return blocked
        }
        guard !playArea.cards.isEmpty else {
            return self
        }
        var copy = self
        for card in copy.playArea.cards where !copy.order.contains(card) {
            copy.order.append(card)
        }
        copy.playArea = PlayArea(cards: [])
        copy.notice = nil
        return copy
    }

    func playStaged() -> TableSession {
        if let blocked = gate() {
            return blocked
        }
        if playArea.cards.isEmpty {
            return refusing("Move cards into the play area first.")
        }
        switch playArea.applied(to: hand) {
        case .success(let next):
            var played = applying(.success(next))
            played.playArea = PlayArea(cards: [])
            return played
        case .failure(let reason):
            if case .ambiguous = playArea.offer(in: hand) {
                return refusing("Those cards fit more than one meld.")
            }
            return refusing(TurnWords.saying(reason))
        }
    }

    func toggleHandOrder() -> TableSession {
        switch handOrder {
        case .suit:
            return sortByRank()
        case .rank:
            return sortBySuit()
        }
    }

    func sortBySuit() -> TableSession {
        if let blocked = gate() {
            return blocked
        }
        var copy = self
        copy.order = TableScene.sortedHand(order)
        copy.handOrder = .suit
        copy.notice = nil
        return copy
    }

    func sortByRank() -> TableSession {
        if let blocked = gate() {
            return blocked
        }
        var copy = self
        copy.order = order.sorted { lhs, rhs in
            if lhs.rank != rhs.rank {
                return lhs.rank.rawValue < rhs.rank.rawValue
            }
            let left = Suit.allCases.firstIndex(of: lhs.suit) ?? 0
            let right = Suit.allCases.firstIndex(of: rhs.suit) ?? 0
            return left < right
        }
        copy.handOrder = .rank
        copy.notice = nil
        return copy
    }

    func stepComputer() -> TableSession {
        guard hand.turn == .computer, hand.handResult == nil else {
            var copy = self
            copy.computerPending = false
            return copy
        }
        switch ComputerTable.step(hand, youScore: match.you, computerScore: match.computer) {
        case .failure(let error):
            var copy = self
            copy.computerPending = false
            copy.notice = "The computer could not move. \(TurnWords.saying(error.rejection))"
            return copy
        case .success(let stepped):
            var copy = self
            copy.notice = nil
            copy.adopt(stepped.state)
            copy.computerLine = TurnWords.computer(stepped.play)
            let stillComputer = stepped.state.turn == .computer && stepped.state.handResult == nil
            copy.computerPending = stillComputer && playsLive
            if stillComputer && playsLive {
                copy.beat += 1
            }
            return copy
        }
    }

    private func dealNextHand() -> TableSession {
        guard let result = hand.handResult else {
            return refusing("This hand is still going.")
        }
        var scored = self
        if !recordedThisHand, case .playing = match.conclusion {
            scored.match = match.record(result)
            scored.recordedThisHand = true
            if case .won(let seat) = scored.match.conclusion {
                scored.notice = seat == .you ? "You reached 500." : "The computer reached 500."
            }
        }
        if case .won = scored.match.conclusion {
            return TableSession.opening(seed: hand.seed.rawValue &+ 1, playsLive: playsLive)
        }
        let next = HandState.deal(
            seed: Seed(hand.seed.rawValue &+ 1),
            rotation: hand.rotation.nextHand()
        )
        return TableSession(hand: next, match: scored.match, playsLive: playsLive)
    }

    func mark(for card: Card) -> CardMark {
        card == owedCard ? .owed : .plain
    }

    private func declining() -> TableSession {
        if let blocked = gate() {
            return blocked
        }
        return applying(hand.declineDiscardPile())
    }

    private func effect(_ drop: CardDrop) -> DropEffect {
        switch drop {
        case .drawStock:
            return played(hand.drawFromStock())
        case .takeDiscard(let payload):
            guard let card = payload.resolvedCard() else {
                return .ignore
            }
            return played(hand.takeDiscard(card))
        case .discard(let payload):
            return discarding(payload)
        case .stage(let payload):
            return staging(payload)
        case .placeInHand(let payload, let index):
            return placing(payload, at: index)
        }
    }

    private func played(_ result: Result<HandState, TurnRejection>) -> DropEffect {
        switch result {
        case .success(let next):
            return .hand(next)
        case .failure(let reason):
            return .refuse(TurnWords.saying(reason))
        }
    }

    private func discarding(_ payload: DraggedCard) -> DropEffect {
        let pool = order + playArea.cards
        guard let card = payload.card(in: pool) else {
            return .ignore
        }
        if playArea.cards.contains(card), playArea.cards.count != 1 {
            return .refuse("Discard one card.")
        }
        return played(hand.discard(card))
    }

    private func staging(_ payload: DraggedCard) -> DropEffect {
        guard let card = payload.card(in: order), !playArea.cards.contains(card) else {
            return .ignore
        }
        var next = order
        next.removeAll { $0 == card }
        return .arranged(order: next, playArea: playArea.adding(card))
    }

    private func placing(_ payload: DraggedCard, at finalIndex: Int) -> DropEffect {
        let pool = order + playArea.cards
        guard let card = payload.card(in: pool) else {
            return .ignore
        }
        if let current = order.firstIndex(of: card) {
            var next = order
            next.remove(at: current)
            let index = min(max(finalIndex, 0), next.count)
            next.insert(card, at: index)
            return .arranged(order: next, playArea: playArea)
        }
        guard playArea.cards.contains(card) else {
            return .ignore
        }
        var next = order
        let index = min(max(finalIndex, 0), next.count)
        next.insert(card, at: index)
        return .arranged(order: next, playArea: playArea.removing(card))
    }

    private func gate() -> TableSession? {
        if hand.handResult != nil {
            return refusing("This hand is over.")
        }
        if hand.turn != .you {
            return refusing("Wait for the computer.")
        }
        return nil
    }

    private func refusing(_ text: String) -> TableSession {
        var copy = self
        copy.notice = text
        return copy
    }

    private func applying(_ result: Result<HandState, TurnRejection>) -> TableSession {
        switch result {
        case .failure(let reason):
            return refusing(TurnWords.saying(reason))
        case .success(let next):
            var copy = self
            copy.notice = nil
            copy.computerLine = nil
            copy.adopt(next)
            if next.handResult != nil {
                copy.computerPending = false
            } else if next.turn == .computer {
                copy.computerPending = playsLive
                if playsLive {
                    copy.beat += 1
                }
            }
            return copy
        }
    }

    private mutating func adopt(_ next: HandState) {
        let cards = next.you.cards
        playArea = PlayArea(cards: playArea.cards.filter { cards.contains($0) })
        let staged = playArea.cards
        let visible = cards.filter { !staged.contains($0) }
        let kept = order.filter { visible.contains($0) }
        let extras = visible.filter { !kept.contains($0) }
        order = kept + extras
        hand = next
        if let result = next.handResult, !recordedThisHand, case .playing = match.conclusion {
            match = match.record(result)
            recordedThisHand = true
            if case .won(let seat) = match.conclusion {
                notice = seat == .you ? "You reached 500." : "The computer reached 500."
            }
        }
    }
}

enum HandOrder: Equatable {
    case suit
    case rank
}

enum CardMark: Equatable {
    case plain
    case owed
}

enum TableCue: Equatable {
    case none
    case draw
    case pass
    case discard
    case handOver

    func glows(_ pile: Pile) -> Bool {
        switch (self, pile) {
        case (.draw, _), (.pass, _):
            return true
        case (.discard, .discard):
            return true
        default:
            return false
        }
    }

    var stockValue: String {
        switch self {
        case .draw:
            return "Draw"
        case .pass:
            return "Leave the pile"
        case .discard, .none, .handOver:
            return ""
        }
    }

    var discardValue: String {
        switch self {
        case .draw, .pass:
            return "Draw"
        case .discard:
            return "Discard"
        case .none, .handOver:
            return ""
        }
    }

    enum Pile: Equatable {
        case stock
        case discard
    }
}

private enum DropEffect: Equatable {
    case hand(HandState)
    case arranged(order: [Card], playArea: PlayArea)
    case refuse(String)
    case ignore
}

enum TableCardID {
    static func hand(_ card: Card) -> String {
        "hand-\(card.rank.rawValue)-\(CardLabel.letter(card.suit))"
    }

    static func discard(_ card: Card) -> String {
        "discard-\(card.rank.rawValue)-\(CardLabel.letter(card.suit))"
    }

    static func staged(_ card: Card) -> String {
        "play-\(card.rank.rawValue)-\(CardLabel.letter(card.suit))"
    }
}

enum TurnWords {
    static func saying(_ rejection: TurnRejection) -> String {
        switch rejection {
        case .handIsOver:
            return "This hand is over."
        case .stillDrawing:
            return "Draw a card before you play."
        case .alreadyDrew:
            return "You already drew. Meld, lay off, or discard."
        case .stockIsEmpty:
            return "The stock is empty."
        case .stockStillHasCards:
            return "The stock still has cards."
        case .discardNotInPile:
            return "That card is not in the discard pile."
        case .discardCannotBeUsed:
            return "Take that card only when you can meld it or lay it off right away."
        case .mustMeldOrLayOffPickedCard(let card):
            return "Play the \(CardLabel.spoken(card)) in a meld or a layoff first."
        case .pickedCardNotUsed:
            return "Include the card you took from the discard."
        case .cardNotInHand:
            return "Those cards are not all in your hand."
        case .noSuchMeld:
            return "That meld is not on the table."
        case .meldRejected(let reason):
            return saying(reason)
        }
    }

    static func saying(_ rejection: MeldRejection) -> String {
        switch rejection {
        case .needsThreeCards:
            return "A new meld needs at least three cards."
        case .fiveOfAKind:
            return "A set holds at most four cards."
        case .duplicateCard:
            return "That card is already in the meld."
        case .mixedSuit:
            return "A run has to stay in one suit."
        case .wrapsAround:
            return "A run cannot turn the corner from king to ace to 2."
        case .notInSequence:
            return "Those cards do not form a run."
        case .doesNotFit:
            return "That card does not fit this meld."
        }
    }

    static func computer(_ play: ComputerPlay) -> String {
        switch play {
        case .drawFromStock:
            return "Computer drew from the stock."
        case .takeDiscard(let card):
            return "Computer took the \(CardLabel.spoken(card))."
        case .declineDiscardPile:
            return "Computer left the discard pile."
        case .layDown(let cards):
            return "Computer laid down \(cards.count) cards."
        case .layOff(let card, _):
            return "Computer laid off the \(CardLabel.spoken(card))."
        case .discard(let card):
            return "Computer discarded the \(CardLabel.spoken(card))."
        }
    }
}

enum TableLaunch {
    static let readyMeld = "readyMeld"

    static func session() -> TableSession {
        session(arguments: ProcessInfo.processInfo.arguments)
    }

    static func session(arguments args: [String]) -> TableSession {
        if let fixture = fixture(in: args) {
            return fixture
        }
        if let preset = preset(in: args) {
            return TableSession(preset: preset, playsLive: true)
        }
        return TableSession.opening(seed: seed(in: args), playsLive: true)
    }

    private static func fixture(in args: [String]) -> TableSession? {
        guard let index = args.firstIndex(of: "-tableFixture"), index + 1 < args.count else {
            return nil
        }
        guard args[index + 1] == readyMeld else {
            return nil
        }
        return TableSession(
            hand: HandState.scriptedPlay()[1],
            match: .opening,
            playsLive: false
        )
    }

    private static func seed(in args: [String]) -> UInt64 {
        guard let index = args.firstIndex(of: "-tableSeed"), index + 1 < args.count else {
            return 0
        }
        return UInt64(args[index + 1]) ?? 0
    }

    private static func preset(in args: [String]) -> TablePreset? {
        guard let index = args.firstIndex(of: "-tablePreset"), index + 1 < args.count else {
            return nil
        }
        switch args[index + 1] {
        case "freshDeal":
            return .freshDeal
        case "midHand":
            return .midHand
        case "longDiscard":
            return .longDiscard
        default:
            return nil
        }
    }
}
