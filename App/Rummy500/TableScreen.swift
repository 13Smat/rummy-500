import RummyEngine
import SwiftUI

struct TableScreen: View {
    @Environment(\.tableHandWidth) private var tableHandWidth
    @State private var session: TableSession
    @GestureState private var lift: CardLift?
    @State private var layout = TableLayout(zones: [:], handSlots: [])

    init(session: TableSession) {
        _session = State(initialValue: session)
    }

    init(preset: TablePreset = .freshDeal, playsLive: Bool = false) {
        self.init(session: TableSession(preset: preset, playsLive: playsLive))
    }

    var body: some View {
        let scene = session.scene
        ZStack {
            WoodGrain()
            VStack(spacing: 0) {
                topCluster(scene)
                scorePill(
                    role: .opponent,
                    title: nil,
                    value: scene.computerScore,
                    identifier: "computer-score",
                    label: "Computer \(scene.computerScore)"
                )
                .padding(.top, 2)
                .zIndex(1)
                felt(scene)
                    .padding(.horizontal, 10)
                    .padding(.top, -12)
                    .frame(maxHeight: .infinity)
                playerRow
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
                yourHand(scene)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .coordinateSpace(name: TableSpace.name)
        .onPreferenceChange(TableLayoutKey.self) { next in
            let settled = next.settled()
            if settled != layout {
                layout = settled
            }
        }
        .overlay { liftedCard }
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

    private func topCluster(_ scene: TableScene) -> some View {
        ZStack(alignment: .top) {
            opponentFan(scene)
                .padding(.top, 6)
            HStack(alignment: .center) {
                placeholder(system: "gearshape.fill", label: "Settings", identifier: "settings")
                Spacer(minLength: 8)
                #if DEBUG
                NavigationLink("Debug") {
                    DealDebugView()
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(.background)
                        .navigationTitle("Debug")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar(.visible, for: .navigationBar)
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                #endif
                Spacer(minLength: 8)
                placeholder(system: "trophy.fill", label: "Trophies", identifier: "trophies")
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
        }
        .frame(height: 78)
    }

    private func placeholder(system name: String, label: String, identifier: String) -> some View {
        Button {} label: {
            Image(systemName: name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(red: 0.98, green: 0.95, blue: 0.88))
                .frame(width: TableChrome.minimumTap, height: TableChrome.minimumTap)
                .background(Color.black.opacity(0.18), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
        .accessibilityHint("Does nothing yet")
    }

    private func opponentFan(_ scene: TableScene) -> some View {
        let shown = min(scene.opponentCount, 13)
        return HStack(spacing: -30) {
            ForEach(0..<shown, id: \.self) { index in
                let mid = Double(max(shown - 1, 0)) / 2
                CardBack(width: 42, height: 58)
                    .rotationEffect(.degrees((Double(index) - mid) * 4), anchor: .bottom)
                    .offset(y: CGFloat(abs(Double(index) - mid)) * 1.1)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70, alignment: .bottom)
        .offset(y: -18)
        .frame(height: 52, alignment: .bottom)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Computer, \(scene.opponentCount) cards, face down")
        .accessibilityIdentifier("opponent-hand")
    }

    private func felt(_ scene: TableScene) -> some View {
        VStack(spacing: 6) {
            turnChip(scene)
            notices
            presetMenu
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    meldBlock(
                        "Your melds",
                        scene.melds(laidDownBy: .you),
                        identifier: "your-melds"
                    )
                    meldBlock(
                        "Computer's melds",
                        scene.melds(laidDownBy: .computer),
                        identifier: "computer-melds"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(alignment: .bottom, spacing: 8) {
                playZone
                pileTray(scene)
                    .frame(width: 176)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(FeltSurface())
    }

    @ViewBuilder
    private var notices: some View {
        if let mustUse = session.mustUseText {
            banner(mustUse, identifier: "must-use")
        }
        if let refusal = session.playRefusal {
            banner(refusal, identifier: "play-refusal")
        }
        if let notice = session.notice {
            banner(notice, identifier: "notice")
        }
        if let computerLine = session.computerLine {
            Text(computerLine)
                .font(.caption)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("computer-line")
        }
        if let result = session.handResultText {
            Text(result)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("hand-result")
        }
    }

    private var presetMenu: some View {
        HStack(spacing: 4) {
            ForEach(TablePreset.allCases) { item in
                Button(item.title) {
                    session = TableSession(preset: item, playsLive: session.playsLive)
                }
                .font(.system(size: 11, weight: item == session.menuPreset ? .bold : .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    Color.white.opacity(item == session.menuPreset ? 0.28 : 0.12),
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

    private func turnChip(_ scene: TableScene) -> some View {
        let chip = Text(scene.turnLabel)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TableChrome.chipInk)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(TableChrome.chip, in: Capsule())
            .accessibilityIdentifier("turn")
        return Group {
            if let title = session.turnActionTitle {
                chip
                    .onTapGesture { session = session.tapTurn() }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction(named: title) { session = session.tapTurn() }
                    .accessibilityLabel("\(scene.turnLabel). \(title)")
            } else {
                chip
            }
        }
    }

    private func banner(_ text: String, identifier: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(TableChrome.chipInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TableChrome.chip, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityIdentifier(identifier)
    }

    private func scorePill(
        role: SeatToken.Role,
        title: String?,
        value: Int,
        identifier: String,
        label: String
    ) -> some View {
        HStack(spacing: 6) {
            SeatToken(role: role)
            VStack(alignment: .leading, spacing: 0) {
                if let title {
                    Text(title)
                        .font(.system(size: 11, weight: .heavy))
                }
                Text("\(value)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(red: 0.07, green: 0.36, blue: 0.24), in: Capsule())
        .overlay(
            Capsule().strokeBorder(
                role == .you ? TableChrome.youGlow : Color.white.opacity(0.35),
                lineWidth: role == .you ? 2 : 1
            )
        )
        .shadow(
            color: role == .you ? TableChrome.youGlow.opacity(0.85) : .clear,
            radius: role == .you ? 6 : 0
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
    }

    private func meldBlock(
        _ title: String,
        _ melds: [TableMeld],
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .accessibilityIdentifier(identifier)
            if melds.isEmpty {
                Text("None")
                    .font(.caption2)
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
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: 4) {
                    ForEach(meld.cards, id: \.card) { entry in
                        meldCard(entry, in: meld)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .frame(height: TableChrome.meld.height + 28)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("meld-\(meld.id)")
        .accessibilityLabel(meld.kindLabel)
    }

    private func meldCard(_ entry: TableMeldCard, in meld: TableMeld) -> some View {
        VStack(spacing: 2) {
            tag(entry, in: meld, seat: .computer)
            CardFace(card: entry.card, metrics: TableChrome.meld)
                .offset(y: entry.playedBy == .you ? 4 : -4)
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

    private func pileTray(_ scene: TableScene) -> some View {
        HStack(alignment: .center, spacing: 6) {
            stockPile(scene)
            discardPile(scene)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TableChrome.trayFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func stockPile(_ scene: TableScene) -> some View {
        let stroke = pileStroke(.stock)
        let button = Button {
            session = session.tapStock()
        } label: {
            stockFace(count: scene.stockCount)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(stroke.color, lineWidth: stroke.width)
                )
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stock, \(scene.stockCount) cards")
        .accessibilityIdentifier("stock")
        .accessibilityValue(session.cue.stockValue)
        .accessibilityAction(named: session.stockActionTitle) {
            session = session.tapStock()
        }
        if scene.stockCount > 0 {
            button.tableCardDrag(DraggedCard.stock, lift: $lift) { payload, location in
                finish(payload, at: location)
            }
        } else {
            button
        }
    }

    @ViewBuilder
    private func stockFace(count: Int) -> some View {
        if count > 0 {
            CardBack(count: count)
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .frame(width: TableChrome.cardWidth, height: TableChrome.cardHeight)
                .overlay {
                    Text("0")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
        }
    }

    private func discardPile(_ scene: TableScene) -> some View {
        let stroke = pileStroke(.discard)
        return VStack(alignment: .leading, spacing: 2) {
            Text("Discard \(scene.discard.count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(TableChrome.chipInk)
                .accessibilityIdentifier("discard")
            ScrollView(.horizontal) {
                HStack(spacing: TableChrome.discardStride - TableChrome.cardWidth) {
                    ForEach(scene.discard, id: \.self) { card in
                        Button {
                            session = session.receive(.takeDiscard(.discard(card)))
                        } label: {
                            CardFace(card: card)
                        }
                        .buttonStyle(.plain)
                        .opacity(isLifted(DraggedCard.discard(card)) ? 0.35 : 1)
                        .tableCardDrag(DraggedCard.discard(card), lift: $lift) { payload, location in
                            finish(payload, at: location)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(CardLabel.spoken(card))
                        .accessibilityIdentifier(TableCardID.discard(card))
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction(named: "Take discard") {
                            session = session.receive(.takeDiscard(.discard(card)))
                        }
                    }
                }
                .padding(.trailing, 2)
            }
            .scrollIndicators(.hidden)
            .frame(height: TableChrome.cardHeight)
        }
        .padding(2)
        .frame(maxWidth: .infinity, minHeight: TableChrome.cardHeight, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(stroke.color, lineWidth: stroke.width)
        )
        .reportsDropFrame(.discard)
        .accessibilityElement(children: .contain)
        .accessibilityValue(session.cue.discardValue)
    }

    private var playerRow: some View {
        HStack(spacing: 6) {
            scorePill(
                role: .you,
                title: "YOU",
                value: session.scene.yourScore,
                identifier: "your-score",
                label: "You \(session.scene.yourScore)"
            )
            roundButton("X", id: "clear-play", label: "Return cards to your hand") {
                session = session.clearPlayArea()
            }
            playButton
            Spacer(minLength: 4)
            sortButton
        }
    }

    private var sortButton: some View {
        Button {
            session = session.toggleHandOrder()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                Text("Sort")
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(minHeight: TableChrome.minimumTap)
            .background(TableChrome.sortFill, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sort")
        .accessibilityIdentifier("sort")
        .accessibilityValue(session.handOrder == .suit ? "By suit" : "By rank")
        .accessibilityHint("Switches suit order and rank order")
    }

    private var playZone: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                if session.playArea.cards.isEmpty {
                    Text("Meld")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, minHeight: TableChrome.cardHeight, alignment: .leading)
                        .padding(.leading, 4)
                } else {
                    ForEach(session.playArea.cards, id: \.self) { card in
                        stagedCard(card)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(minWidth: 120, minHeight: TableChrome.cardHeight + 8, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, minHeight: TableChrome.cardHeight + 12, alignment: .leading)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(zoneHighlighted(.playArea) ? 0.22 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    Color.white.opacity(zoneHighlighted(.playArea) ? 0.95 : 0.35),
                    lineWidth: zoneHighlighted(.playArea) ? 3 : 1
                )
        )
        .reportsDropFrame(.playArea)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Play area, \(session.playArea.cards.count) cards")
        .accessibilityIdentifier("play-area")
        .animation(.easeOut(duration: 0.2), value: session.playArea.cards)
    }

    private func stagedCard(_ card: Card) -> some View {
        Button {
            session = session.unstage(card)
        } label: {
            CardFace(card: card)
                .scaleEffect(1.04)
        }
        .buttonStyle(.plain)
        .opacity(isLifted(DraggedCard.playArea(card)) ? 0.35 : 1)
        .tableCardDrag(DraggedCard.playArea(card), lift: $lift) { payload, location in
            finish(payload, at: location)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(CardLabel.spoken(card)), in the play area")
        .accessibilityIdentifier(TableCardID.staged(card))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Return to hand") {
            session = session.unstage(card)
        }
        .accessibilityAction(named: "Discard") {
            session = session.receive(.discard(.playArea(card)))
        }
    }

    private var playButton: some View {
        Button {
            session = session.playStaged()
        } label: {
            Text("Play")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(session.playIsEnabled ? TableChrome.chipInk : .white)
                .frame(minWidth: 64, minHeight: TableChrome.minimumTap)
                .background(
                    Color.white.opacity(session.playIsEnabled ? 0.95 : 0.22),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .disabled(!session.playIsEnabled)
        .accessibilityLabel("Play")
        .accessibilityIdentifier("play")
        .accessibilityValue(session.playIsEnabled ? "Enabled" : "Disabled")
    }

    private func roundButton(
        _ title: String,
        id: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(minWidth: TableChrome.minimumTap, minHeight: TableChrome.minimumTap)
                .background(Color.white.opacity(0.16), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }

    private var liftedCard: some View {
        Group {
            if let lift {
                if case .stock = lift.payload {
                    CardBack()
                        .liftedForDrag()
                        .position(lift.location)
                        .allowsHitTesting(false)
                } else if let card = lift.payload.card(in: liftableCards) {
                    CardFace(card: card, mark: session.mark(for: card), metrics: liftMetrics(lift.payload))
                        .liftedForDrag()
                        .position(lift.location)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func liftMetrics(_ payload: DraggedCard) -> CardMetrics {
        if case .hand = payload {
            return TableChrome.hand
        }
        return TableChrome.pile
    }

    private var liftableCards: [Card] {
        session.order + session.playArea.cards + session.hand.discard.bottomToTop
    }

    private func finish(_ payload: DraggedCard, at location: CGPoint) {
        guard let drop = CardDragRoute.drop(payload, at: location, in: layout) else {
            return
        }
        session = session.receive(drop)
    }

    private func zoneHighlighted(_ zone: CardDropZone) -> Bool {
        guard let lift,
              let drop = CardDragRoute.drop(lift.payload, at: lift.location, in: layout),
              drop.zone == zone
        else {
            return false
        }
        return session.accepts(drop)
    }

    private func pileStroke(_ pile: TableCue.Pile) -> (color: Color, width: CGFloat) {
        if pile == .discard, zoneHighlighted(.discard) {
            return (.white, 3)
        }
        if session.cue.glows(pile) {
            return (TableChrome.owed, 3)
        }
        return (Color.white.opacity(0.35), 1)
    }

    private func isLifted(_ payload: DraggedCard) -> Bool {
        lift?.payload == payload
    }

    private func yourHand(_ scene: TableScene) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your hand \(scene.yourHand.count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.88))
                .padding(.leading, 10)
                .accessibilityIdentifier("your-hand")
            if tableHandWidth > 1 {
                fan(scene.yourHand, width: tableHandWidth)
            } else {
                GeometryReader { proxy in
                    fan(scene.yourHand, width: proxy.size.width)
                }
                .frame(height: TableChrome.handCardHeight + 14)
            }
        }
        .padding(.bottom, 4)
        .reportsDropFrame(.hand)
        .animation(.easeOut(duration: 0.2), value: session.playArea.cards)
    }

    /// A hand that fits is not in a scroller. A scroller ends the drag at its
    /// edge, so the leftmost card never reaches the discard.
    @ViewBuilder
    private func fan(_ cards: [Card], width available: CGFloat) -> some View {
        let reveal = TableChrome.handReveal(count: cards.count, available: available)
        let spread = TableChrome.fanWidth(count: cards.count, reveal: reveal)
        let lead = max(0, (available - spread) / 2)
        if spread <= available + 0.5 {
            fanRow(cards, lead: lead, reveal: reveal)
        } else {
            ScrollView(.horizontal) {
                fanRow(cards, lead: lead, reveal: reveal)
            }
            .scrollIndicators(.hidden)
            .frame(height: TableChrome.handCardHeight + 14)
        }
    }

    private func fanRow(_ cards: [Card], lead: CGFloat, reveal: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Color.clear.frame(width: lead)
            HStack(alignment: .top, spacing: reveal - TableChrome.handCardWidth) {
                ForEach(Array(cards.enumerated()), id: \.element) { index, card in
                    handCard(card, index: index)
                        .offset(y: TableChrome.handArc(index: index, count: cards.count))
                        .zIndex(Double(index))
                }
            }
            Color.clear.frame(width: lead)
        }
        .frame(height: TableChrome.handCardHeight + 14, alignment: .top)
    }

    private func handCard(_ card: Card, index: Int) -> some View {
        Button {} label: {
            CardFace(card: card, mark: session.mark(for: card), metrics: TableChrome.hand)
                .reportsHandSlot(index: index, card: DraggedCard.hand(card))
        }
        .buttonStyle(.plain)
        .opacity(isLifted(DraggedCard.hand(card)) ? 0.35 : 1)
        .tableCardDrag(DraggedCard.hand(card), lift: $lift) { payload, location in
            finish(payload, at: location)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(handLabel(card))
        .accessibilityIdentifier(TableCardID.hand(card))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Move to play area") {
            session = session.stage(card)
        }
        .accessibilityAction(named: "Discard") {
            session = session.receive(.discard(.hand(card)))
        }
        .accessibilityAction(named: "Move left") {
            session = session.nudge(card, by: -1)
        }
        .accessibilityAction(named: "Move right") {
            session = session.nudge(card, by: 1)
        }
    }

    private func handLabel(_ card: Card) -> String {
        if card == session.owedCard {
            return "\(CardLabel.spoken(card)), play this card"
        }
        return CardLabel.spoken(card)
    }
}

struct CardFace: View {
    let card: Card
    var mark: CardMark = .plain
    var metrics: CardMetrics = TableChrome.pile

    var body: some View {
        let rank = CardLabel.shortRank(card.rank)
        let rankSize = rank.count > 1 ? metrics.rank * 0.78 : metrics.rank
        VStack(alignment: .leading, spacing: -1) {
            Text(rank)
                .font(.system(size: rankSize, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(CardLabel.symbol(card.suit))
                .font(.system(size: metrics.suit))
            Text(CardLabel.letter(card.suit))
                .font(.system(size: metrics.letter, weight: .heavy))
            Spacer(minLength: 0)
        }
        .foregroundStyle(TableChrome.suitInk(card.suit))
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
        .frame(width: metrics.width, height: metrics.height, alignment: .topLeading)
        .background(
            TableChrome.cardFace,
            in: RoundedRectangle(cornerRadius: metrics.radius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: metrics.radius, style: .continuous)
                .strokeBorder(border, lineWidth: mark == .plain ? 1 : 3)
        )
        .shadow(color: .black.opacity(0.22), radius: 1.2, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CardLabel.spoken(card))
    }

    private var border: Color {
        switch mark {
        case .plain:
            return Color.black.opacity(0.18)
        case .owed:
            return TableChrome.owed
        }
    }
}

struct CardBack: View {
    var count: Int? = nil
    var width: CGFloat = TableChrome.cardWidth
    var height: CGFloat = TableChrome.cardHeight

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.11, green: 0.18, blue: 0.36),
                            Color(red: 0.06, green: 0.10, blue: 0.22),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Color(red: 0.78, green: 0.66, blue: 0.38), lineWidth: 1.5)
                .padding(4)
            DiamondMark()
                .stroke(Color(red: 0.78, green: 0.66, blue: 0.38).opacity(0.9), lineWidth: 1)
                .padding(width * 0.22)
            if let count {
                Text("\(count)")
                    .font(.system(size: min(20, width * 0.38), weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.98, green: 0.96, blue: 0.90))
                    .padding(.horizontal, 4)
                    .background(Color(red: 0.06, green: 0.10, blue: 0.22).opacity(0.82), in: Capsule())
            }
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.22), radius: 1.2, y: 1)
        .accessibilityLabel(count.map { "Face-down card, \($0) left" } ?? "Face-down card")
    }
}

private struct DiamondMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
