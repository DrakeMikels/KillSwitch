import SwiftUI

struct MemorySummaryCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let snapshot: MemorySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unified Memory")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(Formatters.memory(snapshot.usedBytes)) / \(Formatters.memory(snapshot.totalBytes))")
                        .font(.title3.weight(.semibold))

                    Text("\(Formatters.memory(snapshot.availableBytes)) available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Text("\(snapshot.pressureLevel.title) Pressure")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(DesignTokens.pressureTint(for: snapshot.pressureLevel).opacity(0.16))
                    )
                    .foregroundStyle(DesignTokens.pressureTint(for: snapshot.pressureLevel))
            }

            MemoryMeterView(
                value: snapshot.usedPercent,
                fillStyle: AnyShapeStyle(
                    DesignTokens.pressureMeterGradient(for: snapshot.pressureLevel)
                ),
                height: DesignTokens.summaryMeterHeight
            )

            HStack {
                Text("Memory in use")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(Formatters.percent(snapshot.usedPercent))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous)
                        .fill(DesignTokens.glassHighlight(for: colorScheme, emphasis: .card))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous)
                .strokeBorder(.quaternary.opacity(0.7))
        )
    }
}
