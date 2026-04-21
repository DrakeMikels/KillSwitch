import SwiftUI

struct FooterBarView: View {
    let statusMessage: String?

    private func openSettingsFromMenuBar() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            AppCommands.openSettings()
        }
    }

    var body: some View {
        HStack {
            Text(statusMessage ?? "Graceful quit keeps save prompts")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer()

            Button("Settings") {
                openSettingsFromMenuBar()
            }
            .killSwitchSecondaryButtonStyle()
            .controlSize(.small)
        }
        .padding(.top, 2)
    }
}
