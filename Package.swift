// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "TSCPrinter",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "TSCPrinter", targets: ["TSCPrinter"])
    ],
    dependencies: [
        .package(name: "Socket", url: "https://github.com/DimaRU/BlueSocket.git", .branch("master")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "TSCPrinter",
            dependencies: [
                "Socket",
                .product(name: "Logging", package: "swift-log")
            ]),
    ]
)
