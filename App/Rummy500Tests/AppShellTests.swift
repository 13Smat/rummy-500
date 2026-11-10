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
}
