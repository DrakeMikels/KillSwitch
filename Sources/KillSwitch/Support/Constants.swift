import CoreGraphics
import Foundation

enum AppConstants {
    static let appName = "KillSwitch"
    static let bundleIdentifier = "com.killswitch.app"
    static let menuBarImageName = "KillSwitchToggleIcon"
    static let menuBarImageExtension = "pdf"
    static let popoverScale: CGFloat = 0.918
    static let popoverWidth: CGFloat = 372 * popoverScale
    static let popoverFallbackHeight: CGFloat = 560 * popoverScale
    static let popoverMaximumHeight: CGFloat = 620 * popoverScale
    static let settingsWindowWidth: CGFloat = 420
    static let settingsWindowHeight: CGFloat = 360
    static let settingsWindowID = "settings"
    static let minimumSystemVersion = "14.0"
    static let topApplicationCount = 6
    static let releasesURL: URL? = nil
}
