import SwiftUI

struct MemoryMeterView: View {
    let value: Double
    let fillStyle: AnyShapeStyle
    let height: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let clampedValue = min(max(value, 0), 1)
            let fillWidth = clampedValue > 0
                ? max(geometry.size.width * clampedValue, height)
                : 0

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.10))

                Capsule(style: .continuous)
                    .fill(fillStyle)
                    .frame(width: fillWidth)
            }
            .overlay {
                Capsule(style: .continuous)
                    .stroke(.white.opacity(0.08))
            }
        }
        .frame(height: height)
    }
}
