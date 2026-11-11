import RummyEngine
import SwiftUI
import UIKit
import XCTest
@testable import Rummy500

final class TableScreenshotTests: XCTestCase {
    @MainActor
    func testRenderEachPresetAtTwoPhoneWidths() {
        renderEachPreset()
    }

    @MainActor
    func testRenderPlayStates() {
        let size = CGSize(width: 375, height: 667)
        let buried = Card(rank: .three, suit: .diamonds)
        let before = TableSession(
            hand: TablePresets.handBeforeLongPick(),
            match: TablePresets.match(.longDiscard),
            playsLive: false,
            menuPreset: .longDiscard
        )
        let picked = before.takeDiscard(buried)
        render(TablePage(session: picked), name: "play-deeper-pick", size: size)
        let other = picked.order.first { $0 != buried }
        let blocked = other.map { picked.receive(.discard(.hand($0))) } ?? picked
        render(TablePage(session: blocked), name: "play-must-use", size: size)
        let opening = TableSession.opening(seed: 0, playsLive: false)
        render(TablePage(session: opening), name: "play-drawing-cue", size: size)
        let drawn = opening.drawFromStock()
        render(TablePage(session: drawn), name: "play-discard-cue", size: size)
        render(TablePage(session: drawn), name: "play-button-free", size: size)
        let refused = opening.playStaged()
        render(TablePage(session: refused), name: "play-refused", size: size)
        let computer = TableSession(preset: .midHand, playsLive: false).stepComputer()
        render(TablePage(session: computer), name: "play-computer", size: size)
        renderPlayArea(size)
    }

    @MainActor
    private func renderPlayArea(_ size: CGSize) {
        let seven = Card(rank: .seven, suit: .hearts)
        let eight = Card(rank: .eight, suit: .hearts)
        let nine = Card(rank: .nine, suit: .hearts)
        let ready = TableSession(hand: HandState.scriptedPlay()[1], match: .opening, playsLive: false)
        render(TablePage(session: ready), name: "play-area-empty", size: size)
        let two = ready.stage(seven).stage(eight)
        render(TablePage(session: two), name: "play-area-invalid", size: size)
        let three = two.stage(nine)
        render(TablePage(session: three), name: "play-area-valid", size: size)
    }

    @MainActor
    private func renderEachPreset() {
        let phones = [
            Phone(name: "iphone-se", width: 375, height: 667),
            Phone(name: "iphone-16-pro-max", width: 440, height: 956),
        ]
        for preset in TablePreset.allCases {
            for phone in phones {
                let page = TablePage(preset: preset, playsLive: false)
                let size = CGSize(width: phone.width, height: phone.height)
                attach(page, name: "\(fileName(preset))-\(phone.name)", size: size)
            }
        }
    }

    @MainActor
    private func render<Content: View>(_ content: Content, name: String, size: CGSize) {
        attach(content, name: name, size: size)
    }

    @MainActor
    private func attach<Content: View>(_ content: Content, name: String, size: CGSize) {
        guard let image = snapshot(content, size: size),
              let data = image.pngData() else {
            XCTFail("Could not render \(name)")
            return
        }
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = "\(name).png"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertGreaterThan(image.size.width, 300, "\(name) did not render a table")
        XCTAssertGreaterThan(data.count, 1_000, "\(name) did not write a picture")
    }

    @MainActor
    private func snapshot<Content: View>(_ content: Content, size: CGSize) -> UIImage? {
        let page = content
            .environment(\.tableSnapshot, true)
            .environment(\.tableHandWidth, size.width)
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: page)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        return renderer.uiImage
    }

    private func fileName(_ preset: TablePreset) -> String {
        switch preset {
        case .freshDeal:
            return "fresh-deal"
        case .midHand:
            return "mid-hand"
        case .longDiscard:
            return "long-discard"
        }
    }
}

private struct Phone {
    let name: String
    let width: CGFloat
    let height: CGFloat
}
