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
    let xPosition: CGFloat
    let containerWidth: CGFloat

    private var conversionFactor: Double {
        displayUnit == .kg ? 1.0 / 2.205 : 1.0
    }

    private var snappedDate: Date {
        let uniqueDates = Set(points.map { Calendar.current.startOfDay(for: $0.date) })
        return uniqueDates.min(by: {
            abs($0.timeIntervalSince(selectedDate)) < abs($1.timeIntervalSince(selectedDate))
        }) ?? selectedDate
    }

    private var nearestPoints: [ChartDataPoint] {
        let target = snappedDate
        return points.filter {
            Calendar.current.isDate($0.date, inSameDayAs: target)
        }
    }

    var body: some View {
        if !nearestPoints.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(snappedDate.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(K.Colors.primary)

                ForEach(nearestPoints) { point in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(K.Colors.chartColor(for: point.exerciseName))
                            .frame(width: 6, height: 6)
                        Text(point.exerciseName)
                            .font(.system(size: 10))
                            .foregroundStyle(K.Colors.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 2)
                        Text("\(Int(point.estimatedOneRM * conversionFactor))")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(K.Colors.primary)
                        Text(displayUnit.label)
                            .font(.system(size: 9))
                            .foregroundStyle(K.Colors.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
            .overlay(
                RoundedRectangle(cornerRadius: K.Radius.sharp)
                    .stroke(K.Colors.surfaceBorder, lineWidth: 0.5)
            )
            .frame(width: 160)
            .position(
                x: min(max(xPosition, 90), containerWidth - 90),
                y: 16
            )
        }
    }
}
