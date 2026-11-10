extension HandState {
    public static func scriptedPlay() -> [HandState] {
        let hearts = [
            Card(rank: .seven, suit: .hearts),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .nine, suit: .hearts),
        ]
        let threes = [
            Card(rank: .three, suit: .clubs),
            Card(rank: .three, suit: .diamonds),
            Card(rank: .three, suit: .spades),
        ]
        var state = HandState(
            you: Hand(cards: hearts + [
                Card(rank: .two, suit: .clubs),
                Card(rank: .four, suit: .clubs),
            ]),
            computer: Hand(cards: threes + [Card(rank: .king, suit: .clubs)]),
            stock: Stock(topToBottom: [
                Card(rank: .two, suit: .diamonds),
                Card(rank: .six, suit: .spades),
            ]),
            discard: DiscardPile(bottomToTop: [
                Card(rank: .three, suit: .hearts),
                Card(rank: .five, suit: .diamonds),
                Card(rank: .nine, suit: .clubs),
            ]),
            melds: [],
            turn: .you,
            phase: .awaitingDraw,
            seed: Seed(0),
            rotation: .opening
        )
        var trace = [state]
        func step(_ result: Result<HandState, TurnRejection>) {
            guard case .success(let next) = result else {
                preconditionFailure("The scripted hand rejected a move.")
            }
            state = next
            trace.append(state)
        }
        step(state.drawFromStock())
        step(state.layDown(hearts))
        step(state.discard(Card(rank: .four, suit: .clubs)))
        step(state.drawFromStock())
        step(state.layDown(threes))
        step(state.discard(Card(rank: .six, suit: .spades)))
        let buried = Card(rank: .three, suit: .hearts)
        step(state.takeDiscard(buried))
        step(state.layOff(buried, onMeldAt: 1))
        step(state.discard(Card(rank: .nine, suit: .clubs)))
        step(state.declineDiscardPile())
        return trace
    }
}
