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

        waitForLabel("Computer's turn", on: turn, timeout: 5)
        XCTAssertTrue(app.staticTexts["computer-line"].waitForExistence(timeout: 5))
        waitForLabel("Your turn", on: turn, timeout: 30)
        XCTAssertEqual(app.staticTexts["phase"].label, "Draw a card")
        XCTAssertTrue(app.staticTexts["computer-line"].exists)
    }

    func testLongDiscardShowsTheCardYouMustPlay() {
        let app = XCUIApplication()
        app.launchArguments = ["-tablePreset", "longDiscard"]
        app.launch()

        let banner = app.staticTexts["must-use"]
        XCTAssertTrue(banner.waitForExistence(timeout: 15))
        XCTAssertEqual(banner.label, "Play the 3 of diamonds before you do anything else.")
    }

    private func waitForLabel(_ label: String, on element: XCUIElement, timeout: TimeInterval) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", label),
            object: element
        )
        wait(for: [expectation], timeout: timeout)
    }
}
