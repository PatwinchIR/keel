import SwiftUI

struct ActivityRingsView: View {
    let rings: ActivityRingData
    let size: CGFloat

    private let lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            // Stand ring (outermost)
            ringArc(
                progress: rings.standProgress,
                color: .cyan,
                diameter: size
            )
            // Exercise ring (middle)
            ringArc(
                progress: rings.exerciseProgress,
                color: K.Colors.accent,
                diameter: size - lineWidth * 2 - 4
            )
            // Move ring (innermost)
            ringArc(
                progress: rings.moveProgress,
                color: .red,
                diameter: size - lineWidth * 4 - 8
            )
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func ringArc(progress: Double, color: Color, diameter: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)
        }
    }
}
