import RummyEngine
import SwiftUI

struct TableScreen: View {
    @State private var preset: TablePreset

    init(preset: TablePreset = .freshDeal) {
        _preset = State(initialValue: preset)
    }

    var body: some View {
        let scene = TableScene.load(preset)
        VStack(spacing: 8) {
            status(scene)
            presetMenu
            opponent(scene)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    meldBlock(
                        "Computer's melds",
                        scene.melds(laidDownBy: .computer),
                        identifier: "computer-melds"
                    )
                    meldBlock(
                        "Your melds",
                        scene.melds(laidDownBy: .you),
                        identifier: "your-melds"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            piles(scene)
                .layoutPriority(1)
            yourHand(scene)
                .layoutPriority(1)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityIdentifier("table-screen")
    }

    private var presetMenu: some View {
        Menu {
            ForEach(TablePreset.allCases) { item in
                Button(item.title) {
                    preset = item
                }
            }
        } label: {
            Text(preset.title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.16), in: Capsule())
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("preset-menu")
    }

    private func status(_ scene: TableScene) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .center) {
                score("You", scene.yourScore, identifier: "your-score")
                Spacer(minLength: 8)
                Text(scene.turnLabel)
                    .font(.headline)
                    .foregroundStyle(TableChrome.chipInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(TableChrome.chip, in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityIdentifier("turn")
                Spacer(minLength: 8)
                score("Computer", scene.computerScore, identifier: "computer-score")
            }
            Text(scene.phaseLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("phase")
        }
    }

    private func score(_ name: String, _ value: Int, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .font(.caption)
            Text("\(value)")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name) \(value)")
        .accessibilityIdentifier(identifier)
    }

    private func opponent(_ scene: TableScene) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Computer")
                    .font(.subheadline.weight(.semibold))
                Text("\(scene.opponentCount) cards")
                    .font(.caption)
            }
            Spacer(minLength: 8)
            HStack(spacing: -20) {
                ForEach(0..<min(scene.opponentCount, 5), id: \.self) { _ in
                    CardBack()
                }
            }
            .accessibilityHidden(true)
        }
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Computer, \(scene.opponentCount) cards, face down")
        .accessibilityIdentifier("opponent-hand")
    }

    private func meldBlock(
        _ title: String,
        _ melds: [TableMeld],
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            if melds.isEmpty {
                Text("None")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            } else {
                ForEach(melds) { meld in
                    meldRow(meld)
                }
            }
        }
        .accessibilityIdentifier(identifier)
    }

    private func meldRow(_ meld: TableMeld) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(meld.kindLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 6) {
                    ForEach(meld.cards, id: \.card) { entry in
                        meldCard(entry, in: meld)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(height: TableChrome.cardHeight + 28)
        }
    }

    private func meldCard(_ entry: TableMeldCard, in meld: TableMeld) -> some View {
        VStack(spacing: 2) {
            tag(entry, in: meld, seat: .computer)
            CardFace(card: entry.card)
                .offset(y: entry.playedBy == .you ? 6 : -6)
            tag(entry, in: meld, seat: .you)
        }
    }

    @ViewBuilder
    private func tag(_ entry: TableMeldCard, in meld: TableMeld, seat: Seat) -> some View {
        if entry.playedBy == seat && entry.playedBy != meld.laidDownBy {
            Text(seat == .you ? "You" : "Computer")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
                .frame(height: 12)
        } else {
            Color.clear.frame(height: 12)
        }
    }

    private func piles(_ scene: TableScene) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                if scene.stockCount > 0 {
                    CardBack()
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.white.opacity(0.7), lineWidth: 1)
                        .frame(width: TableChrome.cardWidth, height: TableChrome.cardHeight)
                }
                Text("Stock \(scene.stockCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Stock, \(scene.stockCount) cards")
            .accessibilityIdentifier("stock")

            VStack(alignment: .leading, spacing: 4) {
                Text("Discard \(scene.discard.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                ScrollView(.horizontal) {
                    HStack(spacing: TableChrome.discardStride - TableChrome.cardWidth) {
                        ForEach(scene.discard, id: \.self) { card in
                            CardFace(card: card)
                        }
                    }
                    .padding(.trailing, 2)
                }
                .frame(height: TableChrome.cardHeight)
                .accessibilityIdentifier("discard")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func yourHand(_ scene: TableScene) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your hand \(scene.yourHand.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            ScrollView(.horizontal) {
                HStack(spacing: TableChrome.handGap) {
                    ForEach(Array(scene.yourHand.enumerated()), id: \.element) { index, card in
                        CardFace(card: card)
                            .padding(
                                .leading,
                                extraSuitGap(scene.yourHand, index: index)
                            )
                    }
                }
            }
            .frame(height: TableChrome.cardHeight)
            .accessibilityIdentifier("your-hand")
        }
    }

    private func extraSuitGap(_ cards: [Card], index: Int) -> CGFloat {
        guard index > 0 else {
            return 0
        }
        return cards[index - 1].suit == cards[index].suit ? 0 : 10
    }
}

struct CardFace: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(CardLabel.shortRank(card.rank))
                .font(.system(size: 17, weight: .semibold))
            Text(CardLabel.symbol(card.suit))
                .font(.system(size: 16))
            Spacer(minLength: 0)
            Text(CardLabel.letter(card.suit))
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(CardLabel.isRed(card.suit) ? TableChrome.redSuit : TableChrome.blackSuit)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .frame(
            width: TableChrome.cardWidth,
            height: TableChrome.cardHeight,
            alignment: .topLeading
        )
        .background(TableChrome.cardFace, in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.black.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CardLabel.spoken(card))
    }
}

struct CardBack: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(TableChrome.cardBack)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.white.opacity(0.7), lineWidth: 1)
                    .padding(5)
            )
            .frame(width: TableChrome.cardWidth, height: TableChrome.cardHeight)
            .accessibilityLabel("Face-down card")
    }
}
