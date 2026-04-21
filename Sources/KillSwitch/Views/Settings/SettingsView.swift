import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.title2.weight(.semibold))

            Form {
                Section("General") {
                    Toggle(
                        "Launch at login",
                        isOn: Binding(
                            get: { settingsStore.settings.launchAtLogin },
                            set: { settingsStore.settings.launchAtLogin = $0 }
                        )
                    )

                    Toggle(
                        "Show Dock icon",
                        isOn: Binding(
                            get: { settingsStore.settings.showDockIcon },
                            set: { settingsStore.settings.showDockIcon = $0 }
                        )
                    )

                    Toggle(
                        "Show app icons",
                        isOn: Binding(
                            get: { settingsStore.settings.showAppIcons },
                            set: { settingsStore.settings.showAppIcons = $0 }
                        )
                    )
                }

                Section("Display") {
                    Picker(
                        "Sort apps by",
                        selection: Binding(
                            get: { settingsStore.settings.sortMode },
                            set: { settingsStore.settings.sortMode = $0 }
                        )
                    ) {
                        ForEach(SortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }

                    Picker(
                        "Refresh interval",
                        selection: Binding(
                            get: { settingsStore.settings.refreshInterval },
                            set: { settingsStore.settings.refreshInterval = $0 }
                        )
                    ) {
                        ForEach(RefreshIntervalOption.allCases) { interval in
                            Text(interval.title).tag(interval)
                        }
                    }

                    Picker(
                        "Baseload limit",
                        selection: Binding(
                            get: { settingsStore.settings.baseloadLimit },
                            set: { settingsStore.settings.baseloadLimit = $0 }
                        )
                    ) {
                        ForEach(BaseloadLimit.allCases) { limit in
                            Text(limit.title).tag(limit)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Restore Defaults", action: settingsStore.restoreDefaults)
                Spacer()
                Button("Done") {
                    NSApp.keyWindow?.close()
                }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
    }
}
