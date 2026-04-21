import Foundation

@MainActor
final class AppServices {
    let settingsStore: SettingsStore
    let menuBarViewModel: MenuBarViewModel

    init(
        settingsStore: SettingsStore? = nil,
        menuBarViewModel: MenuBarViewModel? = nil
    ) {
        let settingsStore = settingsStore ?? SettingsStore()
        self.settingsStore = settingsStore
        self.menuBarViewModel = menuBarViewModel ?? MenuBarViewModel(settingsStore: settingsStore)
    }
}
