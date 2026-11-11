import XCTest

@MainActor
final class PlayRoundUITests: XCTestCase {
    func testASeededHandPlaysOneRound() {
        let app = XCUIApplication()
        app.launch()

        let turn = app.staticTexts["turn"]
        XCTAssertTrue(turn.waitForExistence(timeout: 15))
        XCTAssertEqual(turn.label, "Your turn")

        let hand = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "hand-"))
        XCTAssertTrue(hand.element(boundBy: 0).waitForExistence(timeout: 5))
        hand.element(boundBy: 0).tap()
        app.buttons["discard-action"].tap()

        let notice = app.staticTexts["notice"]
        XCTAssertTrue(notice.waitForExistence(timeout: 3))
        XCTAssertEqual(notice.label, "Draw a card before you play.")

        app.buttons["stock"].tap()
        XCTAssertEqual(app.staticTexts["phase"].label, "Meld or discard")
        app.buttons["discard-action"].tap()

        // The discard tap waits for the app to settle. The computer's pauses
        // finish during that wait, so the turn is already back, and the line
        // it left is the record of the turn.
        let computer = app.staticTexts["computer-line"]
        XCTAssertTrue(computer.waitForExistence(timeout: 8))
        XCTAssertFalse(computer.label.isEmpty)
        XCTAssertEqual(turn.label, "Your turn")
        XCTAssertEqual(app.staticTexts["phase"].label, "Draw a card")
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
    }

    private func playArea(_ app: XCUIApplication) -> XCUIElement {
        let named = app.descendants(matching: .any)["play-area"]
        if named.exists {
            return named
        }
        return app.scrollViews["play-area"]
    }

    private func drag(_ card: XCUIElement, to area: XCUIElement) {
        card.press(forDuration: 0.8, thenDragTo: area)
    }
}
