import SwiftUI

struct ApplicationRowView: View {
    let stat: AppMemoryStat
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                appIcon

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(DesignTokens.applicationSignalColor(for: stat.memoryImpactPercent))
                            .frame(width: 7, height: 7)

                        Text(stat.name)
                            .font(.subheadline.weight(stat.isFrontmost ? .semibold : .regular))
                            .lineLimit(1)

                        if stat.isFrontmost {
                            Text("Active")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }

                    HStack(spacing: 8) {
                        Text(Formatters.memory(stat.memoryBytes))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(Formatters.percent(stat.memoryImpactPercent)) of available")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if stat.processCount > 1 {
                            Text("\(stat.processCount) proc")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer(minLength: 12)

                Button("Quit", action: onQuit)
                    .killSwitchProminentButtonStyle()
                    .controlSize(.small)
            }

            MemoryMeterView(
                value: stat.memoryImpactPercent,
                fillStyle: AnyShapeStyle(
                    DesignTokens.applicationMeterGradient(for: stat.memoryImpactPercent)
                ),
                height: DesignTokens.rowMeterHeight
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var appIcon: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: DesignTokens.rowIconCornerRadius,
                style: .continuous
            )
            .fill(.thinMaterial)

            if let icon = stat.icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 22, height: 22)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                    )
            } else {
                Image(systemName: "app.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 30, height: 30)
    }
}
