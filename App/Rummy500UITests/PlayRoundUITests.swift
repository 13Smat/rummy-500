import XCTest

@MainActor
final class PlayRoundUITests: XCTestCase {
    func testASeededHandPlaysOneRound() {
        let app = XCUIApplication()
        app.launch()

        let turn = app.staticTexts["turn"]
        XCTAssertTrue(turn.waitForExistence(timeout: 15))
        XCTAssertEqual(turn.label, "Your turn")
        XCTAssertFalse(app.buttons["lay-down"].exists)
        XCTAssertFalse(app.buttons["discard-action"].exists)
        XCTAssertFalse(app.buttons["move-left"].exists)
        XCTAssertFalse(app.buttons["move-right"].exists)
        XCTAssertFalse(app.buttons["leave-pile"].exists)
        let sort = app.buttons["sort"]
        XCTAssertTrue(sort.waitForExistence(timeout: 5))
        XCTAssertEqual(sort.value as? String, "By suit")
        XCTAssertFalse(app.buttons["sort-suit"].exists)
        XCTAssertFalse(app.buttons["sort-rank"].exists)
        XCTAssertTrue(app.buttons["play"].exists)
        XCTAssertTrue(app.buttons["clear-play"].exists)
        XCTAssertEqual(app.buttons["stock"].value as? String, "Draw")

        let nine = app.buttons["hand-9-C"]
        let pile = app.buttons["discard-8-D"]
        XCTAssertTrue(nine.waitForExistence(timeout: 5))
        drag(nine, to: pile)
        let notice = app.staticTexts["notice"]
        XCTAssertTrue(notice.waitForExistence(timeout: 3))
        XCTAssertEqual(notice.label, "Draw a card before you play.")

        drag(app.buttons["stock"], to: nine)
        drag(nine, to: pile)

        let computer = app.staticTexts["computer-line"]
        XCTAssertTrue(computer.waitForExistence(timeout: 8))
        XCTAssertFalse(computer.label.isEmpty)
        XCTAssertEqual(turn.label, "Your turn")
    }

    func testAFullTurnUsesOnlyDrags() {
        let app = XCUIApplication()
        app.launchArguments = ["-tableSeed", "11"]
        app.launch()

        let play = app.buttons["play"]
        XCTAssertTrue(play.waitForExistence(timeout: 15))
        let two = app.buttons["hand-2-C"]
        let three = app.buttons["hand-3-C"]
        let four = app.buttons["hand-4-C"]
        XCTAssertTrue(two.waitForExistence(timeout: 5))
        drag(app.buttons["stock"], to: two)
        XCTAssertTrue(playArea(app).waitForExistence(timeout: 5))
        drag(two, to: playArea(app))
        drag(three, to: playArea(app))
        drag(four, to: playArea(app))
        let enabled = NSPredicate(format: "isEnabled == true")
        wait(for: [expectation(for: enabled, evaluatedWith: play)], timeout: 5)
        play.tap()

        let meld = app.descendants(matching: .any)["meld-0"]
        XCTAssertTrue(meld.waitForExistence(timeout: 5))
        XCTAssertTrue(meld.label.contains("Run"))
        XCTAssertFalse(app.buttons["hand-2-C"].exists)
        drag(app.buttons["hand-2-D"], to: app.buttons["discard-1-D"])

        let turn = app.staticTexts["turn"]
        let computer = app.staticTexts["computer-line"]
        XCTAssertTrue(computer.waitForExistence(timeout: 8))
        XCTAssertFalse(computer.label.isEmpty)
        XCTAssertEqual(turn.label, "Your turn")
    }

    func testReorderingTheHandByDrag() {
        let app = XCUIApplication()
        app.launch()

        let nine = app.buttons["hand-9-C"]
        let two = app.buttons["hand-2-D"]
        XCTAssertTrue(nine.waitForExistence(timeout: 15))
        XCTAssertTrue(two.waitForExistence(timeout: 5))
        drag(nine, to: two)

        let hand = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "hand-"))
        let shown = expectation(for: NSPredicate(format: "identifier == %@", "hand-11-C"), evaluatedWith: hand.element(boundBy: 0))
        wait(for: [shown], timeout: 5)
        XCTAssertEqual(hand.element(boundBy: 0).identifier, "hand-11-C")
        XCTAssertEqual(hand.element(boundBy: 1).identifier, "hand-2-D")
        XCTAssertEqual(hand.element(boundBy: 2).identifier, "hand-9-C")
    }

    func testLongDiscardShowsTheCardYouMustPlay() {
        let app = XCUIApplication()
        app.launchArguments = ["-tablePreset", "longDiscard"]
        app.launch()

        let banner = app.staticTexts["must-use"]
        XCTAssertTrue(banner.waitForExistence(timeout: 15))
        XCTAssertEqual(banner.label, "Play the 3 of diamonds before you do anything else.")
    }

    func testDragThreeHeartsAndPlayLaysDownTheRun() {
        let app = XCUIApplication()
        app.launchArguments = ["-tableFixture", "readyMeld"]
        app.launch()

        let play = app.buttons["play"]
        XCTAssertTrue(play.waitForExistence(timeout: 15))
        XCTAssertFalse(play.isEnabled)

        XCTAssertTrue(playArea(app).waitForExistence(timeout: 5))
        let seven = app.buttons["hand-7-H"]
        let eight = app.buttons["hand-8-H"]
        let nine = app.buttons["hand-9-H"]
        XCTAssertTrue(seven.waitForExistence(timeout: 5))
        XCTAssertTrue(eight.waitForExistence(timeout: 5))
        XCTAssertTrue(nine.waitForExistence(timeout: 5))

        drag(seven, to: playArea(app))
        drag(eight, to: playArea(app))
        XCTAssertTrue(app.buttons["play-7-H"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["play-8-H"].waitForExistence(timeout: 3))
        XCTAssertFalse(play.isEnabled)

        drag(nine, to: playArea(app))
        XCTAssertTrue(app.buttons["play-9-H"].waitForExistence(timeout: 3))
        let enabled = NSPredicate(format: "isEnabled == true")
        let turnedOn = expectation(for: enabled, evaluatedWith: play)
        wait(for: [turnedOn], timeout: 5)

        play.tap()

        let meld = app.descendants(matching: .any)["meld-0"]
        XCTAssertTrue(meld.waitForExistence(timeout: 5))
        XCTAssertTrue(meld.label.contains("Run"))
        XCTAssertFalse(app.buttons["hand-7-H"].exists)
        XCTAssertFalse(app.buttons["play-7-H"].exists)
        XCTAssertEqual(app.descendants(matching: .any)["your-score"].label, "You 0")
        XCTAssertFalse(app.buttons["meld-0"].exists)
    }

    private func playArea(_ app: XCUIApplication) -> XCUIElement {
        let scroll = app.scrollViews["play-area"]
        if scroll.waitForExistence(timeout: 5) {
            return scroll
        }
        return app.descendants(matching: .any)["play-area"]
    }

    private func drag(_ card: XCUIElement, to area: XCUIElement) {
        card.press(forDuration: 0.8, thenDragTo: area, withVelocity: .slow, thenHoldForDuration: 0.4)
    }
}
