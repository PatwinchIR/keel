import Foundation

struct PlateBreakdown: Equatable {
    let targetWeight: Double
    let barWeight: Double
    let platesPerSide: [(weight: Double, count: Int)]
    let achievedWeight: Double
    let remainder: Double

    var totalPlateWeight: Double {
        achievedWeight - barWeight
    }

    var isExact: Bool {
        remainder < 0.01
    }

    static func == (lhs: PlateBreakdown, rhs: PlateBreakdown) -> Bool {
        lhs.targetWeight == rhs.targetWeight &&
        lhs.barWeight == rhs.barWeight &&
        lhs.achievedWeight == rhs.achievedWeight
    }
}

struct PlateCalculator {
    /// Calculate plates per side for a given target weight
    /// - Parameters:
    ///   - targetWeight: The total weight to load on the bar
    ///   - barWeight: Weight of the empty bar (typically 45 lbs)
    ///   - availablePlates: Plate weights available, sorted descending (e.g., [45, 35, 25, 10, 5, 2.5])
    /// - Returns: A `PlateBreakdown` describing what plates go on each side
    static func calculate(targetWeight: Double, barWeight: Double, availablePlates: [Double]) -> PlateBreakdown {
        guard targetWeight > barWeight else {
            return PlateBreakdown(
                targetWeight: targetWeight,
                barWeight: barWeight,
                platesPerSide: [],
                achievedWeight: barWeight,
                remainder: max(0, barWeight - targetWeight)
            )
        }

        let weightPerSide = (targetWeight - barWeight) / 2.0
        let sortedPlates = availablePlates.sorted(by: >)

        var remaining = weightPerSide
        var plates: [(weight: Double, count: Int)] = []

        for plate in sortedPlates {
            guard plate > 0, remaining >= plate else { continue }
            let count = Int(remaining / plate)
            if count > 0 {
                plates.append((weight: plate, count: count))
                remaining -= Double(count) * plate
            }
        }

        let loadedPerSide = weightPerSide - remaining
        let achieved = barWeight + (loadedPerSide * 2.0)

        return PlateBreakdown(
            targetWeight: targetWeight,
            barWeight: barWeight,
            platesPerSide: plates,
            achievedWeight: achieved,
            remainder: remaining * 2.0
        )
    }

    /// Format plates as a compact string like "45+25+10 /side"
    static func compactString(for breakdown: PlateBreakdown) -> String {
        guard !breakdown.platesPerSide.isEmpty else { return "Bar only" }

        let parts = breakdown.platesPerSide.flatMap { plate in
            Array(repeating: plate.weight.plateLabel, count: plate.count)
        }

        return parts.joined(separator: "+") + " /side"
    }
}

private extension Double {
    var plateLabel: String {
        if self == self.rounded() && self >= 1 {
            return String(Int(self))
        }
        return String(format: "%.1f", self)
    }
}
