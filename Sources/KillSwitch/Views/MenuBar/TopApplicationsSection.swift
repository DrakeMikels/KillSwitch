import SwiftUI

struct TopApplicationsSection: View {
    @Environment(\.colorScheme) private var colorScheme

    let applications: [AppMemoryStat]
    let unattributedMemoryBytes: UInt64
    let totalMemoryBytes: UInt64
    let onQuit: (AppMemoryStat) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Top Applications")
                    .font(.headline)

                Spacer()

                Text("By memory")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if applications.isEmpty {
                Text("KillSwitch will show memory-heavy user apps here once they qualify for the current filter.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(sectionSurface)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(applications.enumerated()), id: \.element.id) { index, application in
                        VStack(spacing: 0) {
                            ApplicationRowView(
                                stat: application,
                                onQuit: { onQuit(application) }
                            )

                            if index < applications.count - 1 || shouldShowOtherMemoryRow {
                                Divider()
                                    .overlay(.quaternary.opacity(0.5))
                                    .padding(.leading, 56)
                            }
                        }
                    }

                    if shouldShowOtherMemoryRow {
                        SystemMemoryRowView(
                            memoryBytes: unattributedMemoryBytes,
                            percentOfTotal: totalMemoryBytes > 0
                                ? Double(unattributedMemoryBytes) / Double(totalMemoryBytes)
                                : 0
                        )
                    }
                }
                .background(sectionSurface)
            }
        }
    }

    private var shouldShowOtherMemoryRow: Bool {
        guard totalMemoryBytes > 0 else { return false }
        return unattributedMemoryBytes >= 1_073_741_824
            || Double(unattributedMemoryBytes) / Double(totalMemoryBytes) >= 0.15
    }

    private var sectionSurface: some View {
        RoundedRectangle(
            cornerRadius: DesignTokens.sectionCornerRadius,
            style: .continuous
        )
        .fill(.thinMaterial)
        .overlay {
            RoundedRectangle(
                cornerRadius: DesignTokens.sectionCornerRadius,
                style: .continuous
            )
            .fill(DesignTokens.glassHighlight(for: colorScheme, emphasis: .card))
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: DesignTokens.sectionCornerRadius,
                style: .continuous
            )
            .stroke(DesignTokens.sectionStroke(for: colorScheme))
        }
    }
}

private struct SystemMemoryRowView: View {
    let memoryBytes: UInt64
    let percentOfTotal: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "memorychip")
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.blue)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("System / Other Memory")
                        .font(.subheadline)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(Formatters.memory(memoryBytes))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(Formatters.percent(percentOfTotal)) total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Helpers, compressed memory, caches, and non-visible processes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 12)
            }

            MemoryMeterView(
                value: percentOfTotal,
                fillStyle: AnyShapeStyle(DesignTokens.systemProcessGradient),
                height: DesignTokens.rowMeterHeight
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
