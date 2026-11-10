enum MatchLine {
    static let goal = 500

    struct Decision: Equatable {
        let conclusion: Match.Conclusion
        let nextHandBreaksTheTie: Bool
    }

    static func conclude(
        you: Int,
        computer: Int,
        nextHandBreaksTheTie: Bool
    ) -> Decision {
        let bothReached = you >= goal && computer >= goal
        if nextHandBreaksTheTie || bothReached {
            if you == computer {
                return Decision(conclusion: .playing, nextHandBreaksTheTie: true)
            }
            let winner: Seat = you > computer ? .you : .computer
            return Decision(conclusion: .won(winner), nextHandBreaksTheTie: false)
        }
        if you >= goal {
            return Decision(conclusion: .won(.you), nextHandBreaksTheTie: false)
        }
        if computer >= goal {
            return Decision(conclusion: .won(.computer), nextHandBreaksTheTie: false)
        }
        return Decision(conclusion: .playing, nextHandBreaksTheTie: false)
    }
}

public struct Match: Equatable, Sendable {
    public let you: Int
    public let computer: Int
    public let hands: [HandScore]
    public let conclusion: Conclusion

    public enum Conclusion: Equatable, Sendable {
        case playing
        case won(Seat)
    }

    public static let opening = Match(
        you: 0,
        computer: 0,
        hands: [],
        conclusion: .playing,
        nextHandBreaksTheTie: false
    )

    private let nextHandBreaksTheTie: Bool

    public func record(_ result: HandResult) -> Match {
        guard case .playing = conclusion else {
            assertionFailure("The match already has a winner.")
            return self
        }
        let score = result.score
        let youTotal = you + score.you
        let computerTotal = computer + score.computer
        let decision = MatchLine.conclude(
            you: youTotal,
            computer: computerTotal,
            nextHandBreaksTheTie: nextHandBreaksTheTie
        )
        return Match(
            you: youTotal,
            computer: computerTotal,
            hands: hands + [score],
            conclusion: decision.conclusion,
            nextHandBreaksTheTie: decision.nextHandBreaksTheTie
        )
    }

    private init(
        you: Int,
        computer: Int,
        hands: [HandScore],
        conclusion: Conclusion,
        nextHandBreaksTheTie: Bool
    ) {
        assert(hands.reduce(0) { $0 + $1.you } == you)
        assert(hands.reduce(0) { $0 + $1.computer } == computer)
        switch conclusion {
        case .playing:
            if you >= MatchLine.goal || computer >= MatchLine.goal {
                assert(nextHandBreaksTheTie)
                assert(you == computer)
                assert(you >= MatchLine.goal)
                assert(computer >= MatchLine.goal)
            } else if nextHandBreaksTheTie {
                assert(you == computer)
            }
        case .won(let seat):
            assert(nextHandBreaksTheTie == false)
            assert(you != computer)
            let leader: Seat = you > computer ? .you : .computer
            assert(seat == leader)
        }
        self.you = you
        self.computer = computer
        self.hands = hands
        self.conclusion = conclusion
        self.nextHandBreaksTheTie = nextHandBreaksTheTie
    }
}
