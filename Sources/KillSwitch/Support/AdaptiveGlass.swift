import SwiftUI

extension View {
    @ViewBuilder
    func killSwitchGlassCluster(spacing: CGFloat? = 16) -> some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                self
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func killSwitchControlSurface<S: Shape>(in shape: S) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: shape)
        } else {
            self
                .background {
                    shape.fill(.ultraThinMaterial)
                }
                .overlay {
                    shape.stroke(.quaternary.opacity(0.85))
                }
        }
    }

    @ViewBuilder
    func killSwitchSecondaryButtonStyle() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    func killSwitchProminentButtonStyle() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }
}
