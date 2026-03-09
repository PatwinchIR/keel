import Foundation
import HealthKit

@Observable
final class HealthKitService: @unchecked Sendable {
    private let healthStore = HKHealthStore()
    var isAuthorized = false
    var latestBodyWeight: Double?

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
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            isAuthorized = true
            await fetchLatestBodyWeight()
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
}

private extension HKWorkoutConfiguration {
    func apply(_ configure: (HKWorkoutConfiguration) -> Void) -> HKWorkoutConfiguration {
        configure(self)
        return self
    }
}
