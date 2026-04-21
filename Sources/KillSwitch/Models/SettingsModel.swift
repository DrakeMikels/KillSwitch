import Foundation

enum SortMode: String, CaseIterable, Codable, Identifiable {
    case memory
    case name

    var id: String { rawValue }

    var title: String {
        switch self {
        case .memory:
            return "Memory"
        case .name:
            return "Name"
        }
    }
}

enum RefreshIntervalOption: Int, CaseIterable, Codable, Identifiable {
    case three = 3
    case five = 5
    case ten = 10

    var id: Int { rawValue }
    var seconds: TimeInterval { TimeInterval(rawValue) }
    var title: String { "\(rawValue) sec" }
}

enum BaseloadLimit: String, CaseIterable, Codable, Identifiable {
    case auto
    case mb150
    case mb250
    case mb500
    case gb1

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto:
            return "Auto"
        case .mb150:
            return "150 MB"
        case .mb250:
            return "250 MB"
        case .mb500:
            return "500 MB"
        case .gb1:
            return "1 GB"
        }
    }

    func thresholdBytes(for totalMemoryBytes: UInt64) -> UInt64 {
        switch self {
        case .auto:
            let totalGigabytes = Double(totalMemoryBytes) / 1_073_741_824
            if totalGigabytes <= 8.9 {
                return 150 * 1_048_576
            }
            if totalGigabytes <= 16.9 {
                return 250 * 1_048_576
            }
            return 500 * 1_048_576
        case .mb150:
            return 150 * 1_048_576
        case .mb250:
            return 250 * 1_048_576
        case .mb500:
            return 500 * 1_048_576
        case .gb1:
            return 1_073_741_824
        }
    }
}

struct SettingsModel: Codable {
    var launchAtLogin: Bool
    var showDockIcon: Bool
    var showAppIcons: Bool
    var sortMode: SortMode
    var refreshInterval: RefreshIntervalOption
    var baseloadLimit: BaseloadLimit

    static let defaults = SettingsModel(
        launchAtLogin: false,
        showDockIcon: false,
        showAppIcons: true,
        sortMode: .memory,
        refreshInterval: .five,
        baseloadLimit: .auto
    )
}

