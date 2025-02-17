// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MEGAData",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        .library(
            name: "MEGAData",
            targets: ["MEGAData"]),
    ],
    dependencies: [
        .package(path: "../MEGADomain")
    ],
    targets: [
        .target(
            name: "MEGAData",
            dependencies: ["MEGADomain"]),
        .testTarget(
            name: "MEGADataTests",
            dependencies: ["MEGAData"]),
    ]
)
