// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftEvents",
    products: [
        .library(
            name: "SwiftEvents",
            targets: ["SwiftEvents"]),
        ],
    targets: [
        .target(
            name: "SwiftEvents",
            path: "Sources"),
        .testTarget(
            name: "SwiftEventsTests",
            dependencies: ["SwiftEvents"],
            path: "Tests"),
    ]
)
