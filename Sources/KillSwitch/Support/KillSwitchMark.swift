import SwiftUI

struct KillSwitchMark: View {
    enum Variant {
        case menuBar
        case header

        var metrics: Metrics {
            switch self {
            case .menuBar:
                return Metrics(
                    size: CGSize(width: 18, height: 18),
                    lineWidth: 1.45
                )
            case .header:
                return Metrics(
                    size: CGSize(width: 20, height: 20),
                    lineWidth: 1.65
                )
            }
        }
    }

    private let variant: Variant
    private let tint: Color

    init(
        variant: Variant = .menuBar,
        tint: Color = .primary
    ) {
        self.variant = variant
        self.tint = tint
    }

    var body: some View {
        let metrics = variant.metrics

        ZStack {
            RoundedRectangle(
                cornerRadius: metrics.baseHeight * 0.32,
                style: .continuous
            )
            .strokeBorder(tint, lineWidth: metrics.lineWidth)
            .frame(width: metrics.baseWidth, height: metrics.baseHeight)
            .overlay {
                RoundedRectangle(
                    cornerRadius: metrics.baseHeight * 0.18,
                    style: .continuous
                )
                .fill(tint.opacity(0.18))
                .frame(
                    width: metrics.baseWidth * 0.56,
                    height: metrics.slotHeight
                )
            }
            .offset(y: metrics.baseOffsetY)

            Capsule(style: .continuous)
                .fill(tint)
                .frame(width: metrics.leverWidth, height: metrics.leverHeight)
                .rotationEffect(.degrees(-26), anchor: .bottom)
                .offset(x: metrics.leverOffsetX, y: metrics.leverOffsetY)

            Circle()
                .fill(tint)
                .frame(width: metrics.capDiameter, height: metrics.capDiameter)
                .offset(x: metrics.capOffsetX, y: metrics.capOffsetY)
        }
        .frame(width: metrics.size.width, height: metrics.size.height)
        .accessibilityHidden(true)
    }

    struct Metrics {
        let size: CGSize
        let lineWidth: CGFloat

        var baseWidth: CGFloat { size.width * 0.82 }
        var baseHeight: CGFloat { size.height * 0.30 }
        var slotHeight: CGFloat { max(1.0, baseHeight * 0.22) }
        var capDiameter: CGFloat { size.height * 0.24 }
        var leverWidth: CGFloat { max(1.8, size.width * 0.11) }
        var leverHeight: CGFloat { size.height * 0.54 }
        var baseOffsetY: CGFloat { size.height * 0.26 }
        var leverOffsetX: CGFloat { size.width * 0.02 }
        var leverOffsetY: CGFloat { -size.height * 0.10 }
        var capOffsetX: CGFloat { -size.width * 0.16 }
        var capOffsetY: CGFloat { -size.height * 0.33 }
    }
}
