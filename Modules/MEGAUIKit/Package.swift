// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "MEGAUIKit",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        .library(
            name: "MEGAUIKit",
            targets: ["MEGAUIKit"]),
    ],
    dependencies: [
        .package(path: "../MEGAUI"),
        .package(path: "../MEGASwift")
    ],
    targets: [
        .target(
            name: "MEGAUIKit",
            dependencies: ["MEGAUI", "MEGASwift"]),
        .testTarget(
            name: "MEGAUIKitTests",
            dependencies: ["MEGAUIKit"]),
    ]
)
