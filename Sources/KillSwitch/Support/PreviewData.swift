import Foundation

enum PreviewData {
    static let snapshot = MemorySnapshot(
        totalBytes: 16 * 1_073_741_824,
        usedBytes: 11_400_000_000,
        availableBytes: 4_600_000_000,
        usedPercent: 0.71,
        pressureLevel: .high,
        capturedAt: .now
    )

    static let topApplications: [AppMemoryStat] = [
        AppMemoryStat(
            pid: 101,
            name: "Safari",
            bundleIdentifier: "com.apple.Safari",
            icon: nil,
            memoryBytes: 3_400_000_000,
            memoryPercentOfTotal: 0.21,
            memoryImpactPercent: 0.74,
            isFrontmost: true,
            processCount: 9
        ),
        AppMemoryStat(
            pid: 102,
            name: "Figma",
            bundleIdentifier: "com.figma.Desktop",
            icon: nil,
            memoryBytes: 2_100_000_000,
            memoryPercentOfTotal: 0.13,
            memoryImpactPercent: 0.46,
            isFrontmost: false,
            processCount: 5
        ),
        AppMemoryStat(
            pid: 103,
            name: "Slack",
            bundleIdentifier: "com.tinyspeck.slackmacgap",
            icon: nil,
            memoryBytes: 1_400_000_000,
            memoryPercentOfTotal: 0.09,
            memoryImpactPercent: 0.30,
            isFrontmost: false,
            processCount: 6
        ),
    ]
}
