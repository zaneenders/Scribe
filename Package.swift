// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Scribe",
    products: [
        .executable(name: "Client", targets: ["Client"]),
        .executable(name: "Server", targets: ["Server"]),
        .library(name: "Scribe", targets: ["Scribe"]),
    ],
    dependencies: [
        .package(
            url: "git@github.com:apple/swift-nio.git",
            from: "2.64.0")
    ],
    targets: [
        // Examples
        .executableTarget(
            name: "Client",
            dependencies: ["Scribe"]),
        .executableTarget(
            name: "Server",
            dependencies: ["Scribe"]),
        .target(
            name: "Scribe",
            dependencies: [
                "Shared",
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ]),
        .target(
            name: "Shared",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ]),
    ]
)