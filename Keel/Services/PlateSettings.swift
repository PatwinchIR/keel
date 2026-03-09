import Foundation

@Observable
final class PlateSettings {
    private let defaults = UserDefaults.standard

    // Per-unit UserDefaults keys
    private static let weightUnitKey = "plateSettings.weightUnit"
    private static let lbsBarWeightKey = "plateSettings.lbsBarWeight"
    private static let lbsPlatesKey = "plateSettings.lbsPlates"
    private static let kgBarWeightKey = "plateSettings.kgBarWeight"
    private static let kgPlatesKey = "plateSettings.kgPlates"

    // LBS plate set
    static let allLbsPlateOptions: [Double] = [55, 45, 35, 25, 10, 5, 2.5]
    static let defaultLbsPlates: [Double] = [55, 45, 35, 25, 10, 5, 2.5]
    static let defaultLbsBarWeight: Double = 45

    // KG plate set (IWF standard)
    static let allKgPlateOptions: [Double] = [25, 20, 15, 10, 5, 2.5, 2, 1.25, 0.5]
    static let defaultKgPlates: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]
    static let defaultKgBarWeight: Double = 20

    // Legacy aliases
    static let allPlateOptions: [Double] = allLbsPlateOptions
    static let defaultAvailablePlates: [Double] = defaultLbsPlates
    static let defaultBarWeight: Double = defaultLbsBarWeight

    var weightUnit: WeightUnit {
        didSet {
            defaults.set(weightUnit.rawValue, forKey: Self.weightUnitKey)
            if oldValue != weightUnit {
                // Save outgoing unit's config
                saveConfig(for: oldValue)
                // Load incoming unit's config
                loadConfig(for: weightUnit)
            }
        }
    }

    var barWeight: Double {
        didSet { saveConfig(for: weightUnit) }
    }

    var availablePlates: [Double] {
        didSet { saveConfig(for: weightUnit) }
    }

    var currentPlateOptions: [Double] {
        weightUnit == .kg ? Self.allKgPlateOptions : Self.allLbsPlateOptions
    }

    init() {
        let unit: WeightUnit
        if let unitRaw = defaults.string(forKey: Self.weightUnitKey),
           let saved = WeightUnit(rawValue: unitRaw) {
            unit = saved
        } else {
            unit = .lbs
        }

        // Load config for the resolved unit
        let barKey = unit == .kg ? Self.kgBarWeightKey : Self.lbsBarWeightKey
        let platesKey = unit == .kg ? Self.kgPlatesKey : Self.lbsPlatesKey
        let defaultBar = unit == .kg ? Self.defaultKgBarWeight : Self.defaultLbsBarWeight
        let defaultPlates = unit == .kg ? Self.defaultKgPlates : Self.defaultLbsPlates

        self.weightUnit = unit

        if defaults.object(forKey: barKey) != nil {
            self.barWeight = defaults.double(forKey: barKey)
        } else {
            self.barWeight = defaultBar
        }

        if let saved = defaults.array(forKey: platesKey) as? [Double] {
            self.availablePlates = saved
        } else {
            self.availablePlates = defaultPlates
        }
    }

    private func saveConfig(for unit: WeightUnit) {
        let barKey = unit == .kg ? Self.kgBarWeightKey : Self.lbsBarWeightKey
        let platesKey = unit == .kg ? Self.kgPlatesKey : Self.lbsPlatesKey
        defaults.set(barWeight, forKey: barKey)
        defaults.set(availablePlates, forKey: platesKey)
    }

    private func loadConfig(for unit: WeightUnit) {
        let barKey = unit == .kg ? Self.kgBarWeightKey : Self.lbsBarWeightKey
        let platesKey = unit == .kg ? Self.kgPlatesKey : Self.lbsPlatesKey
        let defaultBar = unit == .kg ? Self.defaultKgBarWeight : Self.defaultLbsBarWeight
        let defaultPlates = unit == .kg ? Self.defaultKgPlates : Self.defaultLbsPlates

        if defaults.object(forKey: barKey) != nil {
            barWeight = defaults.double(forKey: barKey)
        } else {
            barWeight = defaultBar
        }

        if let saved = defaults.array(forKey: platesKey) as? [Double] {
            availablePlates = saved
        } else {
            availablePlates = defaultPlates
        }
    }

    func isPlateEnabled(_ plate: Double) -> Bool {
        availablePlates.contains(plate)
    }

    func togglePlate(_ plate: Double) {
        if let index = availablePlates.firstIndex(of: plate) {
            availablePlates.remove(at: index)
        } else {
            availablePlates.append(plate)
            availablePlates.sort(by: >)
        }
    }

    func breakdown(for targetWeight: Double) -> PlateBreakdown {
        PlateCalculator.calculate(
            targetWeight: targetWeight,
            barWeight: barWeight,
            availablePlates: availablePlates
        )
    }
}
