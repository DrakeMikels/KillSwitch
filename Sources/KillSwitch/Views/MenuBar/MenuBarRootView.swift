import SwiftUI

struct MenuBarRootView: View {
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PopoverHeaderView(viewModel: viewModel)
            MemorySummaryCard(snapshot: viewModel.snapshot)
            TopApplicationsSection(
                applications: viewModel.topApplications,
                unattributedMemoryBytes: viewModel.unattributedMemoryBytes,
                totalMemoryBytes: viewModel.snapshot.totalBytes,
                onQuit: viewModel.quit(_:)
            )
            FooterBarView(statusMessage: viewModel.statusMessage)
        }
        .padding(16)
        .background(
            DesignTokens.panelDepthGradient(for: colorScheme)
        )
        .background(
            DesignTokens.panelGlassTint(for: colorScheme)
        )
        .background(
            DesignTokens.glassHighlight(for: colorScheme, emphasis: .panel)
        )
        .overlay {
            Rectangle()
                .fill(DesignTokens.panelSpecularGradient(for: colorScheme))
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DesignTokens.panelEdgeStroke(for: colorScheme), lineWidth: 0.9)
                .allowsHitTesting(false)
        }
        .onAppear(perform: viewModel.startRefreshing)
        .onDisappear(perform: viewModel.stopRefreshing)
    }
}
