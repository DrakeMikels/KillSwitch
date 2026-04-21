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
    targets: [
        .executableTarget(
            name: "KillSwitch",
            path: "Sources/KillSwitch"
        ),
    ]
)
