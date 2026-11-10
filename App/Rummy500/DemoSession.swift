import RummyEngine

enum DemoSession {
    static func generator(seed: UInt64) -> SeededGenerator {
        SeededGenerator(seed: Seed(seed))
    }

    static func deal(seed: UInt64, rotation: DealRotation = .opening) -> Deal {
        Deal.deal(seed: Seed(seed), rotation: rotation)
    }
}
