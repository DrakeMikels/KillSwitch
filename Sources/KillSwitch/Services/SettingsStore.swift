import AppKit
import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let showDockIcon = "showDockIcon"
        static let showAppIcons = "showAppIcons"
        static let sortMode = "sortMode"
        static let refreshInterval = "refreshInterval"
        static let baseloadLimit = "baseloadLimit"
    }

    private let defaults: UserDefaults
    private let loginItemService: LoginItemService

    @Published var settings: SettingsModel {
        didSet {
            persistChanges(from: oldValue)
        }
    }

    init(
        defaults: UserDefaults = .standard,
        loginItemService: LoginItemService = LoginItemService()
    ) {
        self.defaults = defaults
        self.loginItemService = loginItemService
        self.settings = SettingsModel(
            launchAtLogin: defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? SettingsModel.defaults.launchAtLogin,
            showDockIcon: defaults.object(forKey: Keys.showDockIcon) as? Bool ?? SettingsModel.defaults.showDockIcon,
            showAppIcons: defaults.object(forKey: Keys.showAppIcons) as? Bool ?? SettingsModel.defaults.showAppIcons,
            sortMode: SortMode(rawValue: defaults.string(forKey: Keys.sortMode) ?? "") ?? SettingsModel.defaults.sortMode,
            refreshInterval: RefreshIntervalOption(rawValue: defaults.object(forKey: Keys.refreshInterval) as? Int ?? SettingsModel.defaults.refreshInterval.rawValue) ?? SettingsModel.defaults.refreshInterval,
            baseloadLimit: BaseloadLimit(rawValue: defaults.string(forKey: Keys.baseloadLimit) ?? "") ?? SettingsModel.defaults.baseloadLimit
        )
    }

    func restoreDefaults() {
        settings = .defaults
    }

    private func persistChanges(from oldValue: SettingsModel) {
        defaults.set(settings.launchAtLogin, forKey: Keys.launchAtLogin)
        defaults.set(settings.showDockIcon, forKey: Keys.showDockIcon)
        defaults.set(settings.showAppIcons, forKey: Keys.showAppIcons)
        defaults.set(settings.sortMode.rawValue, forKey: Keys.sortMode)
        defaults.set(settings.refreshInterval.rawValue, forKey: Keys.refreshInterval)
        defaults.set(settings.baseloadLimit.rawValue, forKey: Keys.baseloadLimit)

        if settings.showDockIcon != oldValue.showDockIcon {
            DockIconController.apply(showDockIcon: settings.showDockIcon)
        }

        if settings.launchAtLogin != oldValue.launchAtLogin {
            loginItemService.setEnabled(settings.launchAtLogin)
        }
    }
}

@MainActor
enum DockIconController {
    static func apply(showDockIcon: Bool) {
        NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)

        if showDockIcon {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
