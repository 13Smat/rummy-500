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
                    .frame(width: phone.width, height: phone.height)
                guard let image = snapshot(page, size: CGSize(width: phone.width, height: phone.height)),
                      let data = image.pngData() else {
                    XCTFail("Could not render \(preset.title) on \(phone.name)")
                    continue
                }
                let pixels = PixelCount(image)
                let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
                attachment.name = "\(fileName(preset))-\(phone.name).png"
                attachment.lifetime = .keepAlways
                add(attachment)
                XCTAssertGreaterThan(image.size.width, 300)
                XCTAssertGreaterThan(data.count, 5_000)
                XCTAssertGreaterThan(
                    pixels.cardFace,
                    20_000,
                    "\(preset.title) on \(phone.name) did not draw the card faces"
                )
                XCTAssertGreaterThan(
                    pixels.wood,
                    8_000,
                    "\(preset.title) on \(phone.name) did not draw the wood"
                )
                XCTAssertGreaterThan(
                    pixels.felt,
                    8_000,
                    "\(preset.title) on \(phone.name) did not draw the felt"
                )
                XCTAssertLessThan(
                    pixels.missingSymbol,
                    500,
                    "\(preset.title) on \(phone.name) drew a missing image"
                )
                if preset == .freshDeal {
                    XCTAssertGreaterThan(pixels.diamondOnCard, 12, "diamonds on \(phone.name)")
                    XCTAssertGreaterThan(pixels.clubOnCard, 12, "clubs on \(phone.name)")
                    XCTAssertGreaterThan(pixels.heartOnCard, 12, "hearts on \(phone.name)")
                    XCTAssertGreaterThan(pixels.spadeOnCard, 12, "spades on \(phone.name)")
                }
            }
        }
    }

    @MainActor
    private func render<Content: View>(_ content: Content, name: String, size: CGSize) {
        guard let image = snapshot(content.frame(width: size.width, height: size.height), size: size),
              let data = image.pngData() else {
            XCTFail("Could not render \(name)")
            return
        }
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = "\(name).png"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertGreaterThan(PixelCount(image).cardFace, 20_000, "\(name) did not draw the card faces")
    }

    @MainActor
    private func snapshot<Content: View>(_ content: Content, size: CGSize) -> UIImage? {
        if let rendered = renderedImage(content, size: size) {
            return rendered
        }
        return hostedImage(content, size: size)
    }

    @MainActor
    private func renderedImage<Content: View>(_ content: Content, size: CGSize) -> UIImage? {
        let page = content
            .environment(\.tableSnapshot, true)
            .environment(\.tableHandWidth, size.width)
            .frame(width: size.width, height: size.height)
        print("table snapshot start \(Int(size.width))x\(Int(size.height))")
        let renderer = ImageRenderer(content: page)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        let image = renderer.uiImage
        print("table snapshot end \(Int(image?.size.width ?? 0))")
        return image
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
        window.layoutIfNeeded()
        controller.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            window.layer.render(in: context.cgContext)
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
    let wood: Int
    let felt: Int
    let diamondOnCard: Int
    let clubOnCard: Int
    let heartOnCard: Int
    let spadeOnCard: Int

    init(_ image: UIImage) {
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        guard width > 0, height > 0, let cg = image.cgImage else {
            cardFace = 0
            missingSymbol = 0
            wood = 0
            felt = 0
            diamondOnCard = 0
            clubOnCard = 0
            heartOnCard = 0
            spadeOnCard = 0
            return
        }
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        var faces = 0
        var missing = 0
        var woodCount = 0
        var feltCount = 0
        var diamonds = 0
        var clubs = 0
        var hearts = 0
        var spades = 0
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
            func sample(_ x: Int, _ y: Int) -> (UInt8, UInt8, UInt8)? {
                guard x >= 0, y >= 0, x < width, y < height else {
                    return nil
                }
                let start = (y * width + x) * 4
                return (bytes[start], bytes[start + 1], bytes[start + 2])
            }
            func cream(_ red: UInt8, _ green: UInt8, _ blue: UInt8) -> Bool {
                red > 220 && green > 210 && blue > 190
            }
            func nearCream(_ x: Int, _ y: Int) -> Bool {
                let spots = [(8, 0), (-8, 0), (0, 8), (0, -8), (6, 6), (-6, 6)]
                for spot in spots {
                    if let nearby = sample(x + spot.0, y + spot.1), cream(nearby.0, nearby.1, nearby.2) {
                        return true
                    }
                }
                return false
            }
            var index = 0
            var pixel = 0
            while index + 3 < bytes.count {
                let red = bytes[index]
                let green = bytes[index + 1]
                let blue = bytes[index + 2]
                if cream(red, green, blue) {
                    faces += 1
                }
                if red > 220 && green > 160 && green < 220 && blue < 40 {
                    missing += 1
                }
                if red > 100 && red < 200 && green > 50 && green < 150 && blue < 90 && red > green + 20 && green > blue {
                    woodCount += 1
                }
                if green > 70 && green < 170 && green > red + 20 && green > blue + 10 && red < 90 && blue < 120 {
                    feltCount += 1
                }
                let stillNeedInk = diamonds < 40 || clubs < 40 || hearts < 40 || spades < 40
                if stillNeedInk, pixel % 2 == 0 {
                    let diamond = blue > 180 && red < 80 && green < 130
                    let club = red < 40 && green > 120 && green < 190 && blue < 100
                    let heart = red > 170 && green < 80 && blue < 90
                    let spade = red > 8 && red < 40 && green > 8 && green < 40 && blue > 8 && blue < 50
                    if diamond || club || heart || spade {
                        let x = pixel % width
                        let y = pixel / width
                        if nearCream(x, y) {
                            if diamond {
                                diamonds += 1
                            }
                            if club {
                                clubs += 1
                            }
                            if heart {
                                hearts += 1
                            }
                            if spade {
                                spades += 1
                            }
                        }
                    }
                }
                index += 4
                pixel += 1
            }
        }
        cardFace = faces
        missingSymbol = missing
        wood = woodCount
        felt = feltCount
        diamondOnCard = diamonds
        clubOnCard = clubs
        heartOnCard = hearts
        spadeOnCard = spades
    }
}
