// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "MEGASwiftUI",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        .library(
            name: "MEGASwiftUI",
            targets: ["MEGASwiftUI"]),
    ],
    dependencies: [
        .package(path: "../MEGAUI"),
    ],
    targets: [
        .target(
            name: "MEGASwiftUI",
            dependencies: ["MEGAUI"]),
        .testTarget(
            name: "MEGASwiftUITests",
            dependencies: ["MEGASwiftUI"]),
    ]
)
