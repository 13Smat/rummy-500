// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RummyEngine",
    products: [
        .library(name: "RummyEngine", targets: ["RummyEngine"]),
    ],
    targets: [
        .target(name: "RummyEngine"),
        .testTarget(
            name: "RummyEngineTests",
            dependencies: ["RummyEngine"]
        ),
    ]
)
