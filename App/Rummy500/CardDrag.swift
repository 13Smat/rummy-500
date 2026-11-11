import CoreTransferable
import RummyEngine
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DraggedCard: Hashable, Codable, Sendable, Transferable {
    var rank: Int
    var suit: String
    var origin: Origin

    enum Origin: String, Codable, Hashable, Sendable {
        case hand
        case playArea
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }

    static func hand(_ card: Card) -> DraggedCard {
        DraggedCard(rank: card.rank.rawValue, suit: CardLabel.letter(card.suit), origin: .hand)
    }

    static func playArea(_ card: Card) -> DraggedCard {
        DraggedCard(rank: card.rank.rawValue, suit: CardLabel.letter(card.suit), origin: .playArea)
    }

    func card(in cards: [Card]) -> Card? {
        cards.first { $0.rank.rawValue == rank && CardLabel.letter($0.suit) == suit }
    }
}

enum CardDropZone: Hashable {
    case hand
    case playArea
}

enum CardDragIntent: Equatable {
    case stage
    case unstage
}

enum TableSpace {
    static let name = "table"
}

struct CardLift: Equatable {
    var payload: DraggedCard
    var location: CGPoint
}

enum CardDragRoute {
    static func intent(origin: DraggedCard.Origin, zone: CardDropZone) -> CardDragIntent? {
        switch (origin, zone) {
        case (.hand, .playArea):
            return .stage
        case (.playArea, .hand):
            return .unstage
        case (.hand, .hand), (.playArea, .playArea):
            return nil
        }
    }

    static func zone(
        for payload: DraggedCard,
        at location: CGPoint,
        in frames: [CardDropZone: CGRect]
    ) -> CardDropZone? {
        let order: [CardDropZone]
        switch payload.origin {
        case .hand:
            order = [.playArea, .hand]
        case .playArea:
            order = [.hand, .playArea]
        }
        return order.first { zone in
            guard let frame = frames[zone] else {
                return false
            }
            return frame.insetBy(dx: -20, dy: -20).contains(location)
        }
    }
}

struct DropFramesKey: PreferenceKey {
    static var defaultValue: [CardDropZone: CGRect] = [:]

    static func reduce(
        value: inout [CardDropZone: CGRect],
        nextValue: () -> [CardDropZone: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    func reportsDropFrame(_ zone: CardDropZone) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: DropFramesKey.self,
                    value: [zone: proxy.frame(in: .named(TableSpace.name))]
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
