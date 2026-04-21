import Foundation

struct MemorySnapshot {
    let totalBytes: UInt64
    let usedBytes: UInt64
    let availableBytes: UInt64
    let usedPercent: Double
    let pressureLevel: PressureLevel
    let capturedAt: Date

    static let placeholder = MemorySnapshot(
        totalBytes: 16 * 1_073_741_824,
        usedBytes: 8 * 1_073_741_824,
        availableBytes: 8 * 1_073_741_824,
        usedPercent: 0.5,
        pressureLevel: .normal,
        capturedAt: .now
    )
}

