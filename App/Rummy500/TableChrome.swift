import RummyEngine
import SwiftUI

enum TableChrome {
    static let minimumTap: CGFloat = 44
    static let cardWidth: CGFloat = 48
    static let cardHeight: CGFloat = 68
    static let handCardWidth: CGFloat = 46
    static let handCardHeight: CGFloat = 80
    /// Uncovered left edge of each fanned card. Wider than half a card, so the
    /// card's center stays tappable when the next card overlaps it.
    static let minimumHandReveal: CGFloat = 26
    static let comfortableHandReveal: CGFloat = 34
    static let discardStride: CGFloat = 44

    static let pile = CardMetrics(
        width: cardWidth,
        height: cardHeight,
        rank: 16,
        suit: 14,
        letter: 9,
        radius: 6
    )
    static let hand = CardMetrics(
        width: handCardWidth,
        height: handCardHeight,
        rank: 20,
        suit: 16,
        letter: 9,
        radius: 7
    )
    static let meld = CardMetrics(
        width: 44,
        height: 60,
        rank: 14,
        suit: 12,
        letter: 8,
        radius: 5
    )

    static let cardFace = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let redSuit = Color(red: 0.86, green: 0.12, blue: 0.18)
    static let blackSuit = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let diamondInk = Color(red: 0.13, green: 0.35, blue: 0.90)
    static let clubInk = Color(red: 0.00, green: 0.58, blue: 0.22)
    static let chip = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let chipInk = Color(red: 0.10, green: 0.16, blue: 0.14)
    static let owed = Color(red: 0.20, green: 0.85, blue: 0.72)
    static let sortFill = Color(red: 0.18, green: 0.45, blue: 0.95)
    static let youGlow = Color(red: 0.74, green: 1.0, blue: 0.42)
    static let trayFill = Color(red: 0.74, green: 0.86, blue: 0.72)

    static func suitInk(_ suit: Suit) -> Color {
        switch suit {
        case .diamonds:
            return diamondInk
        case .clubs:
            return clubInk
        case .hearts:
            return redSuit
        case .spades:
            return blackSuit
        }
    }

    static func handReveal(count: Int, available: CGFloat) -> CGFloat {
        guard count > 1, available > handCardWidth else {
            return handCardWidth
        }
        let fitted = (available - handCardWidth) / CGFloat(count - 1)
        return min(comfortableHandReveal, max(minimumHandReveal, fitted))
    }

    static func fanWidth(count: Int, reveal: CGFloat) -> CGFloat {
        guard count > 0 else {
            return 0
        }
        if count == 1 {
            return handCardWidth
        }
        return handCardWidth + reveal * CGFloat(count - 1)
    }

    static func handArc(index: Int, count: Int) -> CGFloat {
        guard count > 2 else {
            return 0
        }
        let mid = CGFloat(count - 1) / 2
        let delta = CGFloat(index) - mid
        return delta * delta * 0.22
    }
}

struct CardMetrics: Equatable {
    var width: CGFloat
    var height: CGFloat
    var rank: CGFloat
    var suit: CGFloat
    var letter: CGFloat
    var radius: CGFloat
}

struct WoodGrain: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.74, green: 0.50, blue: 0.28), location: 0),
                .init(color: Color(red: 0.58, green: 0.34, blue: 0.16), location: 0.22),
                .init(color: Color(red: 0.68, green: 0.42, blue: 0.22), location: 0.48),
                .init(color: Color(red: 0.46, green: 0.26, blue: 0.12), location: 0.72),
                .init(color: Color(red: 0.62, green: 0.36, blue: 0.18), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeltSurface: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.46, blue: 0.29),
                        Color(red: 0.07, green: 0.34, blue: 0.21),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color(red: 0.04, green: 0.15, blue: 0.08), lineWidth: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    .padding(5)
            )
            .shadow(color: .black.opacity(0.28), radius: 8, y: 3)
    }
}

struct SeatToken: View {
    enum Role {
        case you
        case opponent
    }

    var role: Role

    var body: some View {
        ZStack {
            Circle()
                .fill(role == .you
                    ? Color(red: 0.93, green: 0.72, blue: 0.46)
                    : Color(red: 0.55, green: 0.72, blue: 0.78))
            Circle()
                .fill(role == .you
                    ? Color(red: 0.36, green: 0.22, blue: 0.12)
                    : Color(red: 0.16, green: 0.27, blue: 0.40))
                .frame(width: 16, height: 16)
                .offset(y: -5)
            Circle()
                .fill(Color(red: 0.96, green: 0.84, blue: 0.70))
                .frame(width: 14, height: 13)
                .offset(y: 3)
            HStack(spacing: 4) {
                Circle().frame(width: 2, height: 2)
                Circle().frame(width: 2, height: 2)
            }
            .foregroundStyle(Color(red: 0.15, green: 0.12, blue: 0.10))
            .offset(y: 2)
        }
        .frame(width: 28, height: 28)
        .overlay(Circle().strokeBorder(Color.white.opacity(0.85), lineWidth: 1))
        .accessibilityHidden(true)
    }
}

private struct TableSnapshotKey: EnvironmentKey {
    static let defaultValue = false
}

private struct TableHandWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var tableSnapshot: Bool {
        get { self[TableSnapshotKey.self] }
        set { self[TableSnapshotKey.self] = newValue }
    }

    var tableHandWidth: CGFloat {
        get { self[TableHandWidthKey.self] }
        set { self[TableHandWidthKey.self] = newValue }
    }
}
