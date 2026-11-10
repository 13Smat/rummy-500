import XCTest
@testable import Rummy500

final class AppShellTests: XCTestCase {
    func testSameSeedMatchesThroughTheApp() {
        var first = DemoSession.generator(seed: 0)
        var second = DemoSession.generator(seed: 0)
        XCTAssertEqual(first.next(), second.next())
        XCTAssertEqual(first.next(), second.next())
    }

    func testDifferentSeedsDifferThroughTheApp() {
        var first = DemoSession.generator(seed: 0)
        var second = DemoSession.generator(seed: 1)
        XCTAssertNotEqual(first.next(), second.next())
    }

    func testSeededSceneListsTheOpeningDeal() {
        let scene = DealScene.load(seed: 0)
        let visible = scene.yourHand + scene.computerHand + scene.discard
        XCTAssertEqual(scene.yourHand.count, 13)
        XCTAssertEqual(scene.computerHand.count, 13)
        XCTAssertEqual(scene.stockCount, 25)
        XCTAssertEqual(scene.discard, ["8 of diamonds"])
        XCTAssertEqual(scene.yourHand.first, "8 of spades")
        XCTAssertEqual(scene.dealerName, "Computer")
        XCTAssertEqual(scene.leaderName, "You")
        XCTAssertEqual(Set(visible).count, visible.count)
        XCTAssertEqual(DealScene.load(seed: 0), scene)
        XCTAssertNotEqual(DealScene.load(seed: 1).yourHand, scene.yourHand)
    }

    func testSeededSceneListsLegalMelds() {
        let scene = DealScene.load(seed: 0)
        XCTAssertEqual(scene.yourMelds, [])
        XCTAssertEqual(
            scene.computerMelds,
            ["Run: 5 of clubs, 6 of clubs, 7 of clubs, 8 of clubs"]
        )
        let richer = DealScene.load(seed: 11)
        XCTAssertEqual(
            richer.yourMelds,
            [
                "Set: 2 of clubs, 2 of diamonds, 2 of spades",
                "Set: 5 of diamonds, 5 of hearts, 5 of spades",
                "Run: 2 of clubs, 3 of clubs, 4 of clubs",
            ]
        )
        XCTAssertEqual(
            richer.computerMelds,
            ["Set: 7 of diamonds, 7 of hearts, 7 of spades"]
        )
    }

    func testBadSeedTextKeepsTheCurrentDeal() {
        let current = DealScene.load(seed: 4)
        let (kept, error) = DealScene.load(seedText: "nope", keeping: current)
        XCTAssertEqual(kept, current)
        XCTAssertEqual(error, "Enter a whole number from 0.")
        let (next, ok) = DealScene.load(seedText: " 8 ", keeping: current)
        XCTAssertNil(ok)
        XCTAssertEqual(next, DealScene.load(seed: 8))
    }

    func testSampleScoreShowsTheHandAndTheMatch() {
        let opening = ScoreScene.opening
        XCTAssertEqual(opening.match.you, 0)
        XCTAssertEqual(opening.match.computer, 0)
        XCTAssertEqual(opening.statusLine, "Playing")
        XCTAssertNil(opening.lastScore)
        XCTAssertTrue(opening.hasAnotherHand)

        let first = opening.scoringNextHand()
        XCTAssertEqual(first.lastScore?.you, 20)
        XCTAssertEqual(first.lastScore?.computer, -15)
        XCTAssertEqual(first.match.you, 20)
        XCTAssertEqual(first.match.computer, -15)
        XCTAssertEqual(first.statusLine, "Playing")
        XCTAssertTrue(first.hasAnotherHand)

        let second = first.scoringNextHand()
        XCTAssertEqual(second.lastScore?.you, 10)
        XCTAssertEqual(second.lastScore?.computer, -10)
        XCTAssertEqual(second.match.you, 30)
        XCTAssertEqual(second.match.computer, -25)
        XCTAssertEqual(second.match.hands.count, 2)
        XCTAssertEqual(second.statusLine, "Playing")
        XCTAssertFalse(second.hasAnotherHand)
        XCTAssertEqual(second.scoringNextHand(), second)
    }

    func testScriptedHandStepsThroughADeepPickAndScores() {
        var scene = TurnScene.opening
        XCTAssertEqual(scene.stockCount, 2)
        XCTAssertEqual(scene.discard, ["3 of hearts", "5 of diamonds", "9 of clubs"])
        XCTAssertEqual(scene.yourHand.first, "7 of hearts")
        XCTAssertEqual(scene.yourHand.count, 5)
        XCTAssertEqual(scene.computerHand.count, 4)
        XCTAssertEqual(scene.melds, [])
        XCTAssertEqual(scene.status, "Your turn to draw")
        XCTAssertNil(scene.yourScore)
        XCTAssertTrue(scene.hasAnotherStep)

        var sawDeepPick = false
        var sawComputerDraw = false
        while scene.hasAnotherStep {
            let discardCount = scene.discard.count
            scene = scene.steppingForward()
            if discardCount - scene.discard.count > 1 {
                sawDeepPick = true
                XCTAssertEqual(scene.status, "You must play the 3 of hearts")
                XCTAssertEqual(scene.discard, [])
                XCTAssertTrue(scene.yourHand.contains("5 of diamonds"))
                XCTAssertTrue(scene.yourHand.contains("9 of clubs"))
                XCTAssertTrue(scene.yourHand.contains("4 of clubs"))
                XCTAssertTrue(scene.yourHand.contains("6 of spades"))
                XCTAssertTrue(scene.yourHand.contains("3 of hearts"))
            }
            if scene.status == "Computer's turn to draw" {
                sawComputerDraw = true
            }
        }

        XCTAssertTrue(sawDeepPick)
        XCTAssertTrue(sawComputerDraw)
        XCTAssertEqual(scene.status, "The stock is empty")
        XCTAssertEqual(scene.stockCount, 0)
        XCTAssertEqual(scene.yourScore, 8)
        XCTAssertEqual(scene.computerScore, -1)
        XCTAssertEqual(scene.yourMatchTotal, 8)
        XCTAssertEqual(scene.computerMatchTotal, -1)
        XCTAssertTrue(scene.melds.contains { $0.contains("3 of hearts (You)") })
        XCTAssertFalse(scene.hasAnotherStep)
        XCTAssertEqual(scene.steppingForward(), scene)
    }

    func testComputerMatchStepsAndFinishes() {
        let scene = ComputerScene.load(seed: 0)
        XCTAssertEqual(scene.yourHand.count, 13)
        XCTAssertEqual(scene.computerHand.count, 13)
        XCTAssertEqual(scene.stockCount, 25)
        XCTAssertEqual(scene.discard.count, 1)
        XCTAssertEqual(scene.lastPlay, "Dealt the hand")
        XCTAssertEqual(scene.matchStatus, "Playing")
        XCTAssertEqual(scene.plays, [])
        XCTAssertTrue(scene.canStep)
        XCTAssertNil(scene.yourHandScore)

        let next = scene.steppingForward()
        XCTAssertEqual(next.plays.count, 1)
        XCTAssertEqual(next.lastPlay, next.plays[0])
        XCTAssertTrue(
            next.lastPlay.hasPrefix("You drew") || next.lastPlay.hasPrefix("You took")
        )
        XCTAssertEqual(ComputerScene.load(seed: 0).steppingForward(), next)

        let (kept, error) = ComputerScene.load(seedText: "nope", keeping: scene)
        XCTAssertEqual(kept, scene)
        XCTAssertEqual(error, "Enter a whole number from 0.")

        let finished = scene.autoplaying()
        XCTAssertFalse(finished.canStep)
        XCTAssertEqual(finished.steppingForward(), finished)
        XCTAssertTrue(finished.matchStatus == "You win" || finished.matchStatus == "Computer wins")
        XCTAssertGreaterThanOrEqual(max(finished.yourMatchTotal, finished.computerMatchTotal), 500)
        XCTAssertGreaterThan(finished.handsPlayed, 0)
        XCTAssertEqual(ComputerScene.load(seed: 0).autoplaying(), finished)
    }

    func testTableScreenLoadsEachPreset() {
        let fresh = TableScene.load(.freshDeal)
        let mid = TableScene.load(.midHand)
        let long = TableScene.load(.longDiscard)

        XCTAssertEqual(fresh.yourHand.count, 13)
        XCTAssertTrue(fresh.melds.isEmpty)
        XCTAssertEqual(fresh.turnLabel, "Your turn")
        XCTAssertGreaterThanOrEqual(mid.melds.count, 2)
        XCTAssertEqual(mid.turnLabel, "Computer's turn")
        XCTAssertGreaterThan(long.yourHand.count, 13)
        XCTAssertGreaterThanOrEqual(long.discard.count, 8)
        XCTAssertEqual(long.turnLabel, "Your turn")
        XCTAssertEqual(
            [fresh.preset, mid.preset, long.preset],
            [TablePreset.freshDeal, .midHand, .longDiscard]
        )
        _ = TableScreen(preset: .freshDeal)
        _ = TableScreen(preset: .midHand)
        _ = TableScreen(preset: .longDiscard)
    }
}
