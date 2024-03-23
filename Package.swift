// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Scribe",
    products: [
        .executable(name: "Client", targets: ["TerminalClient"]),
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
        .target(name: "Programs", dependencies: ["Scribe"]),
        .executableTarget(
            name: "TerminalClient",
            dependencies: ["Scribe"],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags([
                    "-warn-concurrency", "-enable-actor-data-race-checks",
                ]),
            ]
        ),
        .executableTarget(
            name: "Server",
            dependencies: ["Scribe", "Programs"],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags([
                    "-warn-concurrency", "-enable-actor-data-race-checks",
                ]),
            ]
        ),
        .target(
            name: "Scribe",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "_NIOFileSystem", package: "swift-nio"),
            ]),
    ]
)
