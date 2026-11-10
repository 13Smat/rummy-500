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
}
