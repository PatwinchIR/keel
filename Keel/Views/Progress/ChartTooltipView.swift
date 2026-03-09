import SwiftUI
import Charts

struct ChartDataPoint: Identifiable {
    let id: UUID
    let exerciseName: String
    let date: Date
    let estimatedOneRM: Double
    let isCompound: Bool

    init(exerciseName: String, date: Date, estimatedOneRM: Double, isCompound: Bool) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.date = date
        self.estimatedOneRM = estimatedOneRM
        self.isCompound = isCompound
    }
}

struct ChartTooltipView: View {
    let points: [ChartDataPoint]
    let selectedDate: Date
    var displayUnit: WeightUnit = .lbs
    let chartProxy: ChartProxy
    let geometryProxy: GeometryProxy

    private var conversionFactor: Double {
        displayUnit == .kg ? 1.0 / 2.205 : 1.0
    }

    private var nearestPoints: [ChartDataPoint] {
        // Find all points within ±12 hours of selected date
        let threshold: TimeInterval = 12 * 60 * 60
        return points.filter { abs($0.date.timeIntervalSince(selectedDate)) < threshold }
    }

    var body: some View {
        if !nearestPoints.isEmpty {
            let xPos = chartProxy.position(forX: selectedDate) ?? 0

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedDate.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(K.Colors.primary)

                ForEach(nearestPoints) { point in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(K.Colors.chartColor(for: point.exerciseName))
                            .frame(width: 6, height: 6)
                        Text(point.exerciseName)
                            .font(.system(size: 11))
                            .foregroundStyle(K.Colors.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 2)
                        Text("\(Int(point.estimatedOneRM * conversionFactor)) \(displayUnit.label)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(K.Colors.primary)
                    }
                }
            }
            .padding(K.Spacing.sm)
            .background(K.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
            .overlay(
                RoundedRectangle(cornerRadius: K.Radius.sharp)
                    .stroke(K.Colors.surfaceBorder, lineWidth: 0.5)
            )
            .frame(width: 160)
            .position(
                x: min(max(xPos, 90), geometryProxy.size.width - 90),
                y: 20
            )
        }
    }
}
