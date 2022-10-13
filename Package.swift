// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Scheduler",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v2)
    ],
    products: [
        .library(
            name: "Scheduler",
            targets: ["Scheduler"]),
    ],
    targets: [
        .target(
            name: "Scheduler",
            dependencies: []),
        .testTarget(
            name: "SchedulerTests",
            dependencies: ["Scheduler"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
