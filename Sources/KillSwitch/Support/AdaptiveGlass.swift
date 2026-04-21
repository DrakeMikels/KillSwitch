import SwiftUI

extension View {
    @ViewBuilder
    func killSwitchGlassCluster(spacing: CGFloat? = 16) -> some View {
        let _ = spacing
        self
    }

    @ViewBuilder
    func killSwitchControlSurface<S: Shape>(in shape: S) -> some View {
        self
            .background {
                shape.fill(.ultraThinMaterial)
            }
            .overlay {
                shape.stroke(.quaternary.opacity(0.85))
            }
    }

    @ViewBuilder
    func killSwitchSecondaryButtonStyle() -> some View {
        self.buttonStyle(.bordered)
    }

    @ViewBuilder
    func killSwitchProminentButtonStyle() -> some View {
        self.buttonStyle(.borderedProminent)
    }
}
