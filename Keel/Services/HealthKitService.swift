import Foundation
import HealthKit

@Observable
final class HealthKitService: @unchecked Sendable {
    let healthStore = HKHealthStore()
    var isAuthorized = false
    var latestBodyWeight: Double?
    var bodyWeightHistory: [(date: Date, weight: Double)] = []
    var bodyFatHistory: [(date: Date, bodyFat: Double)] = []
    var leanBodyMassHistory: [(date: Date, mass: Double)] = []
    var activityRings = ActivityRingData()

    private var activityTimer: Timer?

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isAvailable else { return }

        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.quantityType(forIdentifier: .leanBodyMass)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.categoryType(forIdentifier: .appleStandHour)!,
            HKObjectType.activitySummaryType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            isAuthorized = true
            await fetchLatestBodyWeight()
            await fetchBodyWeightHistory()
            await fetchBodyFatHistory()
            await fetchLeanBodyMassHistory()
            fetchTodayActivitySummary()
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }

    func fetchLatestBodyWeight() async {
        guard isAvailable, isAuthorized else { return }

        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: bodyMassType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let weight = sample.quantity.doubleValue(for: .pound())
            Task { @MainActor [weak self] in
                self?.latestBodyWeight = weight
            }
        }

        healthStore.execute(query)
    }

    func fetchBodyWeightHistory() async {
        guard isAvailable, isAuthorized else { return }
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(
            sampleType: bodyMassType,
            predicate: nil,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, _ in
            guard let samples = samples as? [HKQuantitySample] else { return }
            let history = samples.map { sample in
                (date: sample.startDate, weight: sample.quantity.doubleValue(for: .pound()))
            }
            Task { @MainActor [weak self] in
                self?.bodyWeightHistory = history
            }
        }
        healthStore.execute(query)
    }

    func fetchBodyFatHistory() async {
        guard isAvailable, isAuthorized else { return }
        guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(
            sampleType: bodyFatType,
            predicate: nil,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, _ in
            guard let samples = samples as? [HKQuantitySample] else { return }
            let history = samples.map { sample in
                (date: sample.startDate, bodyFat: sample.quantity.doubleValue(for: .percent()) * 100)
            }
            Task { @MainActor [weak self] in
                self?.bodyFatHistory = history
            }
        }
        healthStore.execute(query)
    }

    func fetchLeanBodyMassHistory() async {
        guard isAvailable, isAuthorized else { return }
        guard let lbmType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(
            sampleType: lbmType,
            predicate: nil,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, _ in
            guard let samples = samples as? [HKQuantitySample] else { return }
            let history = samples.map { sample in
                (date: sample.startDate, mass: sample.quantity.doubleValue(for: .pound()))
            }
            Task { @MainActor [weak self] in
                self?.leanBodyMassHistory = history
            }
        }
        healthStore.execute(query)
    }

    func saveWorkout(startDate: Date, endDate: Date) async {
        guard isAvailable, isAuthorized else { return }

        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: HKWorkoutConfiguration().apply {
                $0.activityType = .traditionalStrengthTraining
            },
            device: nil
        )

        do {
            try await builder.beginCollection(at: startDate)
            try await builder.endCollection(at: endDate)
            try await builder.finishWorkout()
        } catch {
            print("Failed to save workout to HealthKit: \(error)")
        }
    }

    // MARK: - Activity Rings

    func fetchTodayActivitySummary() {
        guard isAvailable, isAuthorized else { return }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .era], from: Date())
        components.calendar = calendar
        let predicate = HKQuery.predicateForActivitySummary(with: components)

        let query = HKActivitySummaryQuery(predicate: predicate) { [weak self] _, summaries, _ in
            guard let summary = summaries?.first else { return }

            let move = summary.activeEnergyBurned.doubleValue(for: .kilocalorie())
            let moveGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())
            let exercise = summary.appleExerciseTime.doubleValue(for: .minute())
            let exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: .minute())
            let stand = summary.appleStandHours.doubleValue(for: .count())
            let standGoal = summary.appleStandHoursGoal.doubleValue(for: .count())

            Task { @MainActor [weak self] in
                self?.activityRings = ActivityRingData(
                    moveCalories: move,
                    moveGoal: moveGoal,
                    exerciseMinutes: exercise,
                    exerciseGoal: exerciseGoal,
                    standHours: stand,
                    standGoal: standGoal
                )
            }
        }

        healthStore.execute(query)
    }

    /// Start periodic refresh of activity rings (every 60s) during active workout
    func startActivityRingRefresh() {
        stopActivityRingRefresh()
        fetchTodayActivitySummary()
        activityTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchTodayActivitySummary()
        }
    }

    func stopActivityRingRefresh() {
        activityTimer?.invalidate()
        activityTimer = nil
    }
}

private extension HKWorkoutConfiguration {
    func apply(_ configure: (HKWorkoutConfiguration) -> Void) -> HKWorkoutConfiguration {
        configure(self)
        return self
    }
}
