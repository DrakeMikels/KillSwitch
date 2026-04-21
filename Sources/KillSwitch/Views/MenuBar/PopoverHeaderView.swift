import SwiftUI

struct PopoverHeaderView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            HStack(spacing: 12) {
                Image(nsImage: AppIconProvider.headerImage())
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .padding(7)
                    .frame(width: 34, height: 34)
                    .killSwitchControlSurface(
                        in: RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(AppConstants.appName)
                        .font(.headline)

                    Text("Memory utility")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                Button(action: viewModel.refresh) {
                    if viewModel.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                            .frame(
                                width: DesignTokens.floatingControlDiameter,
                                height: DesignTokens.floatingControlDiameter
                            )
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(
                                width: DesignTokens.floatingControlDiameter,
                                height: DesignTokens.floatingControlDiameter
                            )
                    }
                }
                .buttonStyle(.plain)
                .killSwitchControlSurface(in: Circle())
                .help("Refresh now")

                Menu {
                    OverflowMenuContent(viewModel: viewModel)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .frame(
                            width: DesignTokens.floatingControlDiameter,
                            height: DesignTokens.floatingControlDiameter
                        )
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .killSwitchControlSurface(in: Circle())
                .help("Utility menu")
            }
            .killSwitchGlassCluster(spacing: 14)
        }
    }
}
