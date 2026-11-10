import RummyEngine
import SwiftUI

struct TableScreen: View {
    @State private var session: TableSession

    init(session: TableSession) {
        _session = State(initialValue: session)
    }

    init(preset: TablePreset = .freshDeal, playsLive: Bool = false) {
        self.init(session: TableSession(preset: preset, playsLive: playsLive))
    }

    var body: some View {
        let scene = session.scene
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
            actions
                .layoutPriority(1)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task(id: session.beat) {
            guard session.computerPending else {
                return
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else {
                return
            }
            session = session.stepComputer()
        }
    }

    private var presetMenu: some View {
        HStack(spacing: 6) {
            ForEach(TablePreset.allCases) { item in
                Button(item.title) {
                    session = TableSession(preset: item, playsLive: session.playsLive)
                }
                .font(.caption.weight(item == session.menuPreset ? .bold : .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    Color.white.opacity(item == session.menuPreset ? 0.22 : 0.08),
                    in: Capsule()
                )
                .accessibilityAddTraits(item == session.menuPreset ? .isSelected : [])
            }
        }
        .buttonStyle(.plain)
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
            if let mustUse = session.mustUseText {
                banner(mustUse, identifier: "must-use")
            }
            if let notice = session.notice {
                banner(notice, identifier: "notice")
            }
            if let computerLine = session.computerLine {
                Text(computerLine)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("computer-line")
            }
            if let result = session.handResultText {
                Text(result)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("hand-result")
                chip(session.nextHandTitle, id: "deal-next") {
                    session = session.dealNextHand()
                }
            }
        }
    }

    private func banner(_ text: String, identifier: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TableChrome.chipInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TableChrome.chip, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityIdentifier(identifier)
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
                .accessibilityIdentifier(identifier)
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
    }

    private func meldRow(_ meld: TableMeld) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(meld.kindLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: 6) {
                    ForEach(meld.cards, id: \.card) { entry in
                        meldCard(entry, in: meld)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .frame(height: TableChrome.cardHeight + 28)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            session = session.layOffSelection(onMeld: meld.id)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("meld-\(meld.id)")
        .accessibilityLabel("\(meld.kindLabel), lay off here")
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
            Button {
                session = session.drawFromStock()
            } label: {
                VStack(spacing: 4) {
                    if scene.stockCount > 0 {
                        CardBack()
                            .accessibilityHidden(true)
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.white.opacity(0.7), lineWidth: 1)
                            .frame(width: TableChrome.cardWidth, height: TableChrome.cardHeight)
                    }
                    Text("Stock \(scene.stockCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Stock, \(scene.stockCount) cards")
            .accessibilityIdentifier("stock")

            VStack(alignment: .leading, spacing: 4) {
                Text("Discard \(scene.discard.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("discard")
                ScrollView(.horizontal) {
                    HStack(spacing: TableChrome.discardStride - TableChrome.cardWidth) {
                        ForEach(scene.discard, id: \.self) { card in
                            Button {
                                session = session.takeDiscard(card)
                            } label: {
                                CardFace(card: card)
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(CardLabel.spoken(card))
                            .accessibilityIdentifier(TableCardID.discard(card))
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                    .padding(.trailing, 2)
                }
                .scrollIndicators(.hidden)
                .frame(height: TableChrome.cardHeight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func yourHand(_ scene: TableScene) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your hand \(scene.yourHand.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .accessibilityIdentifier("your-hand")
            ScrollView(.horizontal) {
                HStack(spacing: TableChrome.handGap) {
                    ForEach(Array(scene.yourHand.enumerated()), id: \.element) { index, card in
                        Button {
                            session = session.toggle(card)
                        } label: {
                            CardFace(card: card, mark: session.mark(for: card))
                                .padding(.leading, extraSuitGap(scene.yourHand, index: index))
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(handLabel(card))
                        .accessibilityIdentifier(TableCardID.hand(card))
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAddTraits(session.selected.contains(card) ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
            .frame(height: TableChrome.cardHeight)
        }
    }

    private func handLabel(_ card: Card) -> String {
        if card == session.owedCard {
            return "\(CardLabel.spoken(card)), play this card"
        }
        return CardLabel.spoken(card)
    }

    private var actions: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip("Lay down", id: "lay-down") {
                    session = session.layDownSelection()
                }
                chip("Discard", id: "discard-action") {
                    session = session.discardSelection()
                }
                chip("By suit", id: "sort-suit", label: "Sort by suit") {
                    session = session.sortBySuit()
                }
                chip("By rank", id: "sort-rank", label: "Sort by rank") {
                    session = session.sortByRank()
                }
                chip("Move left", id: "move-left") {
                    session = session.moveSelection(by: -1)
                }
                chip("Move right", id: "move-right") {
                    session = session.moveSelection(by: 1)
                }
                if session.showsLeavePile {
                    chip("Leave the pile", id: "leave-pile") {
                        session = session.leaveThePile()
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(height: 44)
    }

    private func chip(
        _ title: String,
        id: String,
        label: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color.white.opacity(0.16), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label ?? title)
        .accessibilityIdentifier(id)
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
    var mark: CardMark = .plain

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
                .strokeBorder(border, lineWidth: mark == .plain ? 1 : 3)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CardLabel.spoken(card))
    }

    private var border: Color {
        switch mark {
        case .plain:
            return Color.black.opacity(0.18)
        case .selected:
            return .white
        case .owed:
            return TableChrome.owed
        }
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
