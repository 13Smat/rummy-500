import CoreTransferable
import RummyEngine
import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum DraggedCard: Hashable, Codable, Sendable, Transferable {
    case hand(rank: Int, suit: String)
    case playArea(rank: Int, suit: String)
    case discard(rank: Int, suit: String)
    case stock

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }

    static func hand(_ card: Card) -> DraggedCard {
        DraggedCard.hand(rank: card.rank.rawValue, suit: CardLabel.letter(card.suit))
    }

    static func playArea(_ card: Card) -> DraggedCard {
        DraggedCard.playArea(rank: card.rank.rawValue, suit: CardLabel.letter(card.suit))
    }

    static func discard(_ card: Card) -> DraggedCard {
        DraggedCard.discard(rank: card.rank.rawValue, suit: CardLabel.letter(card.suit))
    }

    func card(in cards: [Card]) -> Card? {
        let rank: Int
        let suit: String
        switch self {
        case .hand(let value, let letter),
             .playArea(let value, let letter),
             .discard(let value, let letter):
            rank = value
            suit = letter
        case .stock:
            return nil
        }
        return cards.first { $0.rank.rawValue == rank && CardLabel.letter($0.suit) == suit }
    }

    func resolvedCard() -> Card? {
        let rankValue: Int
        let suitLetter: String
        switch self {
        case .hand(let value, let letter),
             .playArea(let value, let letter),
             .discard(let value, let letter):
            rankValue = value
            suitLetter = letter
        case .stock:
            return nil
        }
        guard let rank = Rank(rawValue: rankValue),
              let suit = Suit.allCases.first(where: { CardLabel.letter($0) == suitLetter })
        else {
            return nil
        }
        return Card(rank: rank, suit: suit)
    }
}

enum CardDropZone: Hashable {
    case hand
    case playArea
    case discard
}

enum CardDrop: Equatable {
    case drawStock
    case takeDiscard(DraggedCard)
    case discard(DraggedCard)
    case stage(DraggedCard)
    case placeInHand(DraggedCard, at: Int)

    var zone: CardDropZone {
        switch self {
        case .drawStock, .takeDiscard, .placeInHand:
            return .hand
        case .discard:
            return .discard
        case .stage:
            return .playArea
        }
    }
}

struct HandSlot: Equatable {
    var index: Int
    var card: DraggedCard
    var frame: CGRect
}

struct TableLayout: Equatable {
    var zones: [CardDropZone: CGRect]
    var handSlots: [HandSlot]

    func slotsInOrder() -> [HandSlot] {
        var latest: [Int: HandSlot] = [:]
        for slot in handSlots {
            latest[slot.index] = slot
        }
        return latest.keys.sorted().compactMap { latest[$0] }
    }
}

struct TableLayoutKey: PreferenceKey {
    static var defaultValue: TableLayout { TableLayout(zones: [:], handSlots: []) }

    static func reduce(value: inout TableLayout, nextValue: () -> TableLayout) {
        let next = nextValue()
        value.zones.merge(next.zones, uniquingKeysWith: { _, new in new })
        value.handSlots.append(contentsOf: next.handSlots)
    }
}

enum TableSpace {
    static let name = "table"
}

struct CardLift: Equatable {
    var payload: DraggedCard
    var location: CGPoint
}

enum CardDragRoute {
    static func drop(
        _ payload: DraggedCard,
        at location: CGPoint,
        in layout: TableLayout
    ) -> CardDrop? {
        switch payload {
        case .stock:
            return hits(.hand, at: location, in: layout, slop: 20) ? .drawStock : nil
        case .discard(_, _):
            return hits(.hand, at: location, in: layout, slop: 20) ? .takeDiscard(payload) : nil
        case .hand(_, _), .playArea(_, _):
            if hits(.discard, at: location, in: layout, slop: 0) {
                return .discard(payload)
            }
            if case .hand = payload, hits(.playArea, at: location, in: layout, slop: 20) {
                return .stage(payload)
            }
            guard hits(.hand, at: location, in: layout, slop: 20) else {
                return nil
            }
            guard let index = nearestIndex(to: location, in: layout) else {
                return nil
            }
            return .placeInHand(payload, at: index)
        }
    }

    private static func hits(
        _ zone: CardDropZone,
        at location: CGPoint,
        in layout: TableLayout,
        slop: CGFloat
    ) -> Bool {
        guard let frame = layout.zones[zone] else {
            return false
        }
        return frame.insetBy(dx: -slop, dy: -slop).contains(location)
    }

    private static func nearestIndex(to location: CGPoint, in layout: TableLayout) -> Int? {
        let slots = layout.slotsInOrder()
        guard !slots.isEmpty else {
            return nil
        }
        return slots.min { lhs, rhs in
            let left = distance(lhs.frame, location)
            let right = distance(rhs.frame, location)
            if left == right {
                return lhs.index < rhs.index
            }
            return left < right
        }?.index
    }

    private static func distance(_ frame: CGRect, _ location: CGPoint) -> CGFloat {
        let dx = frame.midX - location.x
        let dy = frame.midY - location.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

extension View {
    func reportsDropFrame(_ zone: CardDropZone) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: TableLayoutKey.self,
                    value: TableLayout(
                        zones: [zone: proxy.frame(in: .named(TableSpace.name)).integral],
                        handSlots: []
                    )
                )
            }
        )
    }

    func reportsHandSlot(index: Int, card: DraggedCard) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: TableLayoutKey.self,
                    value: TableLayout(
                        zones: [:],
                        handSlots: [
                            HandSlot(
                                index: index,
                                card: card,
                                frame: proxy.frame(in: .named(TableSpace.name)).integral
                            )
                        ]
                    )
                )
            }
        )
    }

    func tableCardDrag(
        _ payload: DraggedCard,
        lift: GestureState<CardLift?>,
        onDrop: @escaping (DraggedCard, CGPoint) -> Void
    ) -> some View {
        background(ScrollTouchPass())
            .highPriorityGesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .named(TableSpace.name))
                    .updating(lift) { value, state, _ in
                        state = CardLift(payload: payload, location: value.location)
                    }
                    .onEnded { value in
                        onDrop(payload, value.location)
                    }
            )
    }
}

private struct ScrollTouchPass: UIViewRepresentable {
    func makeUIView(context: Context) -> PassView {
        PassView()
    }

    func updateUIView(_ uiView: PassView, context: Context) {}

    final class PassView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            nil
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            var current: UIView? = self
            while let view = current {
                if let scroll = view as? UIScrollView {
                    scroll.canCancelContentTouches = false
                    scroll.delaysContentTouches = false
                }
                current = view.superview
            }
        }
    }
}

extension CardFace {
    func liftedForDrag() -> some View {
        scaleEffect(1.08)
            .shadow(color: .black.opacity(0.35), radius: 6, y: 6)
    }
}

extension CardBack {
    func liftedForDrag() -> some View {
        scaleEffect(1.08)
            .shadow(color: .black.opacity(0.35), radius: 6, y: 6)
    }
}
