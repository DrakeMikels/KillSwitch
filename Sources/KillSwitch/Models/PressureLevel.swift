import Foundation

enum PressureLevel: String, CaseIterable, Codable {
    case normal
    case elevated
    case high
    case critical

    var title: String {
        switch self {
        case .normal:
            return "Normal"
        case .elevated:
            return "Elevated"
        case .high:
            return "High"
        case .critical:
            return "Critical"
        }
    }

    var menuBarSymbolName: String {
        if #available(macOS 26.0, *) {
            switch self {
            case .normal:
                return "lightswitch.off"
            case .elevated:
                return "lightswitch.on"
            case .high, .critical:
                return "lightswitch.on.fill"
            }
        } else {
            switch self {
            case .normal:
                return "power.circle"
            case .elevated, .high, .critical:
                return "power.circle.fill"
            }
        }
    }
}
