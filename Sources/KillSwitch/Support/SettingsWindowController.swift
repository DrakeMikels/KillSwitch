import AppKit
import OSLog
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private let logger = Logger(
        subsystem: AppConstants.bundleIdentifier,
        category: "Settings"
    )
    private var configuredStoreID: ObjectIdentifier?
    private weak var settingsStore: SettingsStore?

    private init() {
        super.init(window: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        logger.notice(
            "show settings requested dockIcon=\(settingsStore.settings.showDockIcon, privacy: .public) existingWindow=\(self.window != nil, privacy: .public)"
        )

        if window == nil {
            let hostingController = NSHostingController(
                rootView: SettingsView(settingsStore: settingsStore)
            )

            let window = NSWindow(contentViewController: hostingController)
            window.title = "Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.collectionBehavior = [.moveToActiveSpace]
            window.isReleasedWhenClosed = false
            window.center()
            window.setContentSize(
                NSSize(
                    width: AppConstants.settingsWindowWidth,
                    height: AppConstants.settingsWindowHeight
                )
            )
            window.delegate = self
            self.window = window
            configuredStoreID = ObjectIdentifier(settingsStore)
            logger.notice("Created settings window")
        } else if configuredStoreID != ObjectIdentifier(settingsStore) {
            contentHostingController?.rootView = SettingsView(settingsStore: settingsStore)
            configuredStoreID = ObjectIdentifier(settingsStore)
            logger.notice("Rebound settings window to current store")
        }

        if !settingsStore.settings.showDockIcon {
            NSApp.setActivationPolicy(.regular)
            logger.notice("Temporarily promoted activation policy to regular")
        }

        showWindow(nil)
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
        logger.notice("Attempted to present settings window visible=\(self.window?.isVisible ?? false, privacy: .public)")
    }

    private var contentHostingController: NSHostingController<SettingsView>? {
        window?.contentViewController as? NSHostingController<SettingsView>
    }

    func windowWillClose(_ notification: Notification) {
        logger.notice("Settings window closing")
        let showDockIcon = settingsStore?.settings.showDockIcon ?? SettingsModel.defaults.showDockIcon
        DockIconController.apply(showDockIcon: showDockIcon)
        NSApp.hide(nil)
    }
}
