import RummyEngine

enum DemoSession {
    static func generator(seed: UInt64) -> SeededGenerator {
        SeededGenerator(seed: Seed(seed))
    }
}
