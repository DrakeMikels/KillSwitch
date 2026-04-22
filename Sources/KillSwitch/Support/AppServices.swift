import Foundation

@MainActor
final class AppServices {
    let settingsStore: SettingsStore
    let updateService: UpdateService
    let menuBarViewModel: MenuBarViewModel

    init(
        settingsStore: SettingsStore? = nil,
        updateService: UpdateService? = nil,
        menuBarViewModel: MenuBarViewModel? = nil
    ) {
        let settingsStore = settingsStore ?? SettingsStore()
        let updateService = updateService ?? UpdateService()
        self.settingsStore = settingsStore
        self.updateService = updateService
        self.menuBarViewModel = menuBarViewModel ?? MenuBarViewModel(
            settingsStore: settingsStore,
            updateService: updateService
        )
    }
}
