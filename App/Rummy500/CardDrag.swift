import CoreTransferable
import RummyEngine
import SwiftUI
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

enum CardDropZone: Equatable {
    case hand
    case playArea
}

enum CardDragIntent: Equatable {
    case stage
    case unstage
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
}

extension View {
    func cardDrop(
        _ zone: CardDropZone,
        targeted: Binding<Bool>,
        accept: @escaping (DraggedCard) -> Bool
    ) -> some View {
        dropDestination(for: DraggedCard.self) { items, _ in
            guard let drag = items.first else {
                return false
            }
            return accept(drag)
        } isTargeted: { hovering in
            targeted.wrappedValue = hovering
        }
    }
}

extension CardFace {
    func liftedForDrag() -> some View {
        scaleEffect(1.08)
            .shadow(color: .black.opacity(0.35), radius: 6, y: 6)
    }
}
