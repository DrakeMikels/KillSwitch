// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "KillSwitch",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "KillSwitch",
            targets: ["KillSwitch"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            exact: "2.9.1"
        ),
    ],
    targets: [
        .executableTarget(
            name: "KillSwitch",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/KillSwitch"
        ),
    ]
)
