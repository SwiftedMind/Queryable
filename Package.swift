// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Queryable",
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
            dependencies: []),
        .testTarget(
            name: "QueryableTests",
            dependencies: ["Queryable"]),
    ]
)
