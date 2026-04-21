import AppKit

struct AppMemoryStat: Identifiable {
    let pid: pid_t
    let name: String
    let bundleIdentifier: String?
    let icon: NSImage?
    let memoryBytes: UInt64
    let memoryPercentOfTotal: Double
    let memoryImpactPercent: Double
    let isFrontmost: Bool
    let processCount: Int

    var id: pid_t { pid }
}
