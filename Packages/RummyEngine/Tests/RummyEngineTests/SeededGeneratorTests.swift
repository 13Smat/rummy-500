import XCTest
@testable import RummyEngine

final class SeededGeneratorTests: XCTestCase {
    func testSeedZeroMatchesTheSplitMix64Stream() {
        var generator = SeededGenerator(seed: Seed(0))
        let draws = (0..<4).map { _ in generator.next() }
        XCTAssertEqual(
            draws,
            [
                0xE220A8397B1DCDAF,
                0x6E789E6AA1B965F4,
                0x06C45D188009454F,
                0xF88BB8A8724C81EC,
            ]
        )
    }

    func testSeedOneMatchesTheSplitMix64Stream() {
        var generator = SeededGenerator(seed: Seed(1))
        let draws = (0..<4).map { _ in generator.next() }
        XCTAssertEqual(
            draws,
            [
                0x910A2DEC89025CC1,
                0xBEEB8DA1658EEC67,
                0xF893A2EEFB32555E,
                0x71C18690EE42C90B,
            ]
        )
    }

    func testSameSeedProducesTheSameShuffle() {
        let cards = Array(1...13)
        var first = SeededGenerator(seed: Seed(42))
        var second = SeededGenerator(seed: Seed(42))
        XCTAssertEqual(
            cards.shuffled(using: &first),
            cards.shuffled(using: &second)
        )
    }

    func testCopyKeepsItsPlaceInTheSequence() {
        var original = SeededGenerator(seed: Seed(0))
        var copy = original
        XCTAssertEqual(original.next(), copy.next())
    }

    func testDifferentSeedsDivergeOnTheFirstDraw() {
        var first = SeededGenerator(seed: Seed(0))
        var second = SeededGenerator(seed: Seed(1))
        XCTAssertNotEqual(first.next(), second.next())
    }
}
