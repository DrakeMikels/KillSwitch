import SwiftUI

struct OverflowMenuContent: View {
    @ObservedObject var viewModel: MenuBarViewModel

    private func openSettingsFromMenuBar() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            AppCommands.openSettings()
        }
    }

    var body: some View {
        Button("Refresh Now", action: viewModel.refresh)

        Button("Check for Updates…", action: viewModel.checkForUpdates)
            .disabled(!viewModel.isUpdateCheckAvailable)

        Button("About KillSwitch", action: viewModel.openAboutPanel)

        Button("Settings…") {
            openSettingsFromMenuBar()
        }

        Divider()

        Button("Quit KillSwitch") {
            NSApp.terminate(nil)
        }
    }
}
