import SwiftUI

enum DesignTokens {
    static let cardCornerRadius: CGFloat = 16
    static let sectionCornerRadius: CGFloat = 18
    static let rowIconCornerRadius: CGFloat = 8
    static let floatingControlDiameter: CGFloat = 30
    static let summaryMeterHeight: CGFloat = 12
    static let rowMeterHeight: CGFloat = 10
    static let cardHighlightOpacityDark: Double = 0.05
    static let cardHighlightOpacityLight: Double = 0.14
    static let panelHighlightOpacityDark: Double = 0.08
    static let panelHighlightOpacityLight: Double = 0.10
    static let panelGlassTintOpacityDark: Double = 0.08
    static let panelGlassTintOpacityLight: Double = 0.18

    static func pressureTint(for level: PressureLevel) -> Color {
        switch level {
        case .normal:
            return .green
        case .elevated:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }

    static func pressureMeterGradient(for level: PressureLevel) -> LinearGradient {
        switch level {
        case .normal:
            return LinearGradient(
                colors: [.mint, .green],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .elevated:
            return LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .high:
            return LinearGradient(
                colors: [.orange, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .critical:
            return LinearGradient(
                colors: [.red, .pink],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    static func applicationSignalColor(for percentage: Double) -> Color {
        switch percentage {
        case 0.5...:
            return .red
        case 0.2...:
            return .yellow
        default:
            return .green
        }
    }

    static func applicationMeterGradient(for percentage: Double) -> LinearGradient {
        switch percentage {
        case 0.5...:
            return LinearGradient(
                colors: [.orange, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
        case 0.2...:
            return LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
                colors: [.mint, .green],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    static var systemProcessGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.92),
                Color.indigo.opacity(0.86),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func glassHighlight(for colorScheme: ColorScheme, emphasis: GlassHighlightEmphasis) -> Color {
        let opacity: Double

        switch (colorScheme, emphasis) {
        case (.dark, .panel):
            opacity = panelHighlightOpacityDark
        case (.light, .panel):
            opacity = panelHighlightOpacityLight
        case (.dark, .card):
            opacity = cardHighlightOpacityDark
        case (.light, .card):
            opacity = cardHighlightOpacityLight
        @unknown default:
            opacity = panelHighlightOpacityDark
        }

        return .white.opacity(opacity)
    }

    static func panelGlassTint(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return .black.opacity(panelGlassTintOpacityDark)
        case .light:
            return .white.opacity(panelGlassTintOpacityLight)
        @unknown default:
            return .black.opacity(panelGlassTintOpacityDark)
        }
    }

    static func panelDepthGradient(for colorScheme: ColorScheme) -> LinearGradient {
        switch colorScheme {
        case .dark:
            return LinearGradient(
                colors: [
                    .white.opacity(0.10),
                    .white.opacity(0.04),
                    .black.opacity(0.06),
                    .black.opacity(0.12),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .light:
            return LinearGradient(
                colors: [
                    .white.opacity(0.18),
                    .white.opacity(0.10),
                    .white.opacity(0.04),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        @unknown default:
            return LinearGradient(
                colors: [
                    .white.opacity(0.08),
                    .white.opacity(0.02),
                    .black.opacity(0.18),
                    .black.opacity(0.28),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    static func panelSpecularGradient(for colorScheme: ColorScheme) -> LinearGradient {
        switch colorScheme {
        case .dark:
            return LinearGradient(
                colors: [
                    .white.opacity(0.22),
                    .white.opacity(0.10),
                    .white.opacity(0.03),
                    .clear,
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.38)
            )
        case .light:
            return LinearGradient(
                colors: [
                    .white.opacity(0.20),
                    .white.opacity(0.08),
                    .clear,
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.34)
            )
        @unknown default:
            return LinearGradient(
                colors: [
                    .white.opacity(0.22),
                    .white.opacity(0.10),
                    .white.opacity(0.03),
                    .clear,
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.38)
            )
        }
    }

    static func panelEdgeStroke(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return .white.opacity(0.22)
        case .light:
            return .white.opacity(0.30)
        @unknown default:
            return .white.opacity(0.22)
        }
    }

    static func sectionStroke(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return .white.opacity(0.10)
        case .light:
            return .black.opacity(0.08)
        @unknown default:
            return .white.opacity(0.10)
        }
    }

    enum GlassHighlightEmphasis {
        case panel
        case card
    }
}
