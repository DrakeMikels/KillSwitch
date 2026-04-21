import AppKit
import OSLog

@MainActor
enum AppCommands {
    private static let logger = Logger(
        subsystem: AppConstants.bundleIdentifier,
        category: "Settings"
    )
    private static weak var settingsStore: SettingsStore?
    private static var closePopover: (() -> Void)?

    static func configure(
        settingsStore: SettingsStore,
        closePopover: (() -> Void)? = nil
    ) {
        self.settingsStore = settingsStore
        self.closePopover = closePopover
    }

    static func openSettings() {
        logger.notice("openSettings requested configuredStore=\(settingsStore != nil, privacy: .public)")
        guard let settingsStore else { return }

        closePopover?()
        SettingsWindowController.shared.show(settingsStore: settingsStore)
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.activate(ignoringOtherApps: true)
    }
}
