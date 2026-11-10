public struct Seed: Hashable, Sendable {
    public let rawValue: UInt64

    public init(_ rawValue: UInt64) {
        self.rawValue = rawValue
    }
}
