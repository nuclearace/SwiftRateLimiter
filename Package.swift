// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SwiftRateLimiter",
    products: [
        .library(name: "SwiftRateLimiter", targets: ["SwiftRateLimiter"])
    ],
    targets: [
        .target(name: "SwiftRateLimiter")
    ]
)
