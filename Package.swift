// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Queryable",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "Queryable",
            targets: ["Queryable"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Queryable",
            dependencies: []
        ),
        .testTarget(
            name: "QueryableTests",
            dependencies: ["Queryable"]
        )
    ]
)
