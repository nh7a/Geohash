// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "Geohash",
    products: [
        .library(
            name: "Geohash",
            targets: ["Geohash"]),
    ],
    targets: [
        .target(
            name: "Geohash",
            dependencies: []),
        .testTarget(
            name: "GeohashTests",
            dependencies: ["Geohash"]),
    ]
)
