import SwiftUI
import UIKit
import XCTest
@testable import Rummy500

final class TableScreenshotTests: XCTestCase {
    func testRenderEachPresetAtTwoPhoneWidths() async {
        await MainActor.run {
            renderEachPreset()
        }
    }

    @MainActor
    private func renderEachPreset() {
        let phones = [
            Phone(name: "iphone-se", width: 375, height: 667),
            Phone(name: "iphone-16-pro-max", width: 440, height: 956),
        ]
        for preset in TablePreset.allCases {
            for phone in phones {
                let page = TablePage(preset: preset)
                    .frame(width: phone.width, height: phone.height)
                let renderer = ImageRenderer(content: page)
                renderer.scale = 2
                renderer.proposedSize = ProposedViewSize(width: phone.width, height: phone.height)
                guard let image = renderer.uiImage, let data = image.pngData() else {
                    XCTFail("Could not render \(preset.title) on \(phone.name)")
                    continue
                }
                XCTAssertGreaterThan(image.size.width, 300)
                XCTAssertGreaterThan(data.count, 5_000)
                let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
                attachment.name = "\(fileName(preset))-\(phone.name).png"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
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
