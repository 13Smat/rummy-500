import RummyEngine

struct ScoreScene: Equatable {
    let match: Match
    let lastScore: HandScore?
    let nextIndex: Int

    static let opening = ScoreScene(match: .opening, lastScore: nil, nextIndex: 0)

    var hasAnotherHand: Bool {
        nextIndex < Self.script.count && match.conclusion == .playing
    }

    var statusLine: String {
        switch match.conclusion {
        case .playing:
            return "Playing"
        case .won(.you):
            return "You win"
        case .won(.computer):
            return "Computer wins"
        }
    }

    func scoringNextHand() -> ScoreScene {
        guard hasAnotherHand else {
            return self
        }
        let result = Self.script[nextIndex]
        return ScoreScene(
            match: match.record(result),
            lastScore: result.score,
            nextIndex: nextIndex + 1
        )
    }

    private static let script: [HandResult] = [
        HandResult(
            you: .init(table: [
                Card(rank: .ace, suit: .hearts),
                Card(rank: .two, suit: .hearts),
                Card(rank: .three, suit: .hearts),
            ]),
            computer: .init(hand: [
                Card(rank: .ace, suit: .spades),
            ])
        ),
        HandResult(
            you: .init(table: [
                Card(rank: .ten, suit: .clubs),
            ]),
            computer: .init(
                table: [Card(rank: .five, suit: .diamonds)],
                hand: [Card(rank: .ace, suit: .clubs)]
            )
        ),
    ]
}
