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
    private func renderEachPreset() {
        let phones = [
            Phone(name: "iphone-se", width: 375, height: 667),
            Phone(name: "iphone-16-pro-max", width: 440, height: 956),
        ]
        for preset in TablePreset.allCases {
            for phone in phones {
                let page = TablePage(preset: preset)
                    .frame(width: phone.width, height: phone.height)
                guard let image = snapshot(page, size: CGSize(width: phone.width, height: phone.height)),
                      let data = image.pngData() else {
                    XCTFail("Could not render \(preset.title) on \(phone.name)")
                    continue
                }
                let pixels = PixelCount(image)
                XCTAssertGreaterThan(image.size.width, 300)
                XCTAssertGreaterThan(data.count, 5_000)
                XCTAssertGreaterThan(
                    pixels.cardFace,
                    20_000,
                    "\(preset.title) on \(phone.name) did not draw the card faces"
                )
                XCTAssertLessThan(
                    pixels.missingSymbol,
                    500,
                    "\(preset.title) on \(phone.name) drew a missing image"
                )
                let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
                attachment.name = "\(fileName(preset))-\(phone.name).png"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    @MainActor
    private func snapshot<Content: View>(_ content: Content, size: CGSize) -> UIImage? {
        let candidates = [renderedImage(content, size: size), hostedImage(content, size: size)]
        return candidates.compactMap { $0 }.max { PixelCount($0).cardFace < PixelCount($1).cardFace }
    }

    @MainActor
    private func renderedImage<Content: View>(_ content: Content, size: CGSize) -> UIImage? {
        let page = content.frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: page)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        return renderer.uiImage
    }

    @MainActor
    private func hostedImage<Content: View>(_ content: Content, size: CGSize) -> UIImage? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let controller = UIHostingController(rootView: content)
        controller.safeAreaRegions = []
        let bounds = CGRect(origin: .zero, size: size)
        let window = scene.map { UIWindow(windowScene: $0) } ?? UIWindow(frame: bounds)
        window.frame = bounds
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = bounds
        window.layoutIfNeeded()
        let drawn = XCTestExpectation(description: "SwiftUI draws the table")
        DispatchQueue.main.async {
            drawn.fulfill()
        }
        XCTWaiter().wait(for: [drawn], timeout: 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            if !window.drawHierarchy(in: bounds, afterScreenUpdates: true) {
                window.layer.render(in: context.cgContext)
            }
        }
        window.isHidden = true
        return image
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

private struct PixelCount {
    let cardFace: Int
    let missingSymbol: Int

    init(_ image: UIImage) {
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        guard width > 0, height > 0, let cg = image.cgImage else {
            cardFace = 0
            missingSymbol = 0
            return
        }
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        var faces = 0
        var missing = 0
        pixels.withUnsafeMutableBytes { raw in
            guard let context = CGContext(
                data: raw.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
                    | CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return
            }
            context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            let bytes = raw.bindMemory(to: UInt8.self)
            var index = 0
            while index + 3 < bytes.count {
                let red = bytes[index]
                let green = bytes[index + 1]
                let blue = bytes[index + 2]
                if red > 220 && green > 210 && blue > 190 {
                    faces += 1
                }
                if red > 220 && green > 160 && green < 220 && blue < 40 {
                    missing += 1
                }
                index += 4
            }
        }
        cardFace = faces
        missingSymbol = missing
    }
}
