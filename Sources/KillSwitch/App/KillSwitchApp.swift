import AppKit
import SwiftUI

struct AppSettingsCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") {
                AppCommands.openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}

@main
struct KillSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let appServices: AppServices

    @MainActor
    init() {
        let appServices = AppServices()
        self.appServices = appServices
        AppDelegate.configure(appServices: appServices)
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            AppSettingsCommands()
        }
    }
}
