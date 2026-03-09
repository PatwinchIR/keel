import Foundation
import HealthKit

@Observable
final class WorkoutSessionService: NSObject, @unchecked Sendable {
    private let healthStore = HKHealthStore()
    private var workoutBuilder: HKWorkoutBuilder?
    private var hrQuery: HKAnchoredObjectQuery?
    private var timer: Timer?
    private var sessionStartDate: Date?

    var isSessionActive = false
    var isPaused = false
    var heartRate: Double = 0
    var activeCalories: Double = 0
    var elapsedTime: TimeInterval = 0

    private var pausedAccumulated: TimeInterval = 0
    private var lastResumeDate: Date?

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var formattedElapsedTime: String {
        let total = Int(elapsedTime)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Session Lifecycle

    func startSession(activityType: HKWorkoutActivityType = .traditionalStrengthTraining) {
        guard isAvailable, !isSessionActive else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = .indoor

        workoutBuilder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: configuration,
            device: .local()
        )

        let now = Date()
        sessionStartDate = now
        lastResumeDate = now
        pausedAccumulated = 0

        Task {
            do {
                try await workoutBuilder?.beginCollection(at: now)
            } catch {
                print("Failed to begin workout collection: \(error)")
            }
        }

        isSessionActive = true
        isPaused = false
        startTimer()
        startHeartRateQuery(from: now)
    }

    func pauseSession() {
        guard isSessionActive, !isPaused else { return }
        isPaused = true
        if let resume = lastResumeDate {
            pausedAccumulated += Date().timeIntervalSince(resume)
        }
        lastResumeDate = nil
        stopTimer()
    }

    func resumeSession() {
        guard isSessionActive, isPaused else { return }
        isPaused = false
        lastResumeDate = Date()
        startTimer()
    }

    func endSession() {
        guard isSessionActive else { return }
        stopTimer()
        stopHeartRateQuery()

        // Final elapsed calculation
        if !isPaused, let resume = lastResumeDate {
            pausedAccumulated += Date().timeIntervalSince(resume)
        }
        elapsedTime = pausedAccumulated

        let endDate = Date()

        Task {
            do {
                // Add active energy sample if we have calories
                if activeCalories > 0, let startDate = sessionStartDate {
                    if let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                        let calSample = HKQuantitySample(
                            type: calType,
                            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: activeCalories),
                            start: startDate,
                            end: endDate
                        )
                        try await workoutBuilder?.addSamples([calSample])
                    }
                }

                try await workoutBuilder?.endCollection(at: endDate)
                try await workoutBuilder?.finishWorkout()
            } catch {
                print("Failed to end workout: \(error)")
            }

            await MainActor.run {
                self.resetState()
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, !self.isPaused else { return }
            Task { @MainActor in
                var total = self.pausedAccumulated
                if let resume = self.lastResumeDate {
                    total += Date().timeIntervalSince(resume)
                }
                self.elapsedTime = total
                self.updateEstimatedCalories()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Heart Rate Observation

    private func startHeartRateQuery(from startDate: Date) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)

        hrQuery = HKAnchoredObjectQuery(
            type: hrType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        hrQuery?.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        if let hrQuery {
            healthStore.execute(hrQuery)
        }
    }

    private func stopHeartRateQuery() {
        if let hrQuery {
            healthStore.stop(hrQuery)
        }
        hrQuery = nil
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample],
              let latest = quantitySamples.last else { return }

        let hrUnit = HKUnit.count().unitDivided(by: .minute())
        let bpm = latest.quantity.doubleValue(for: hrUnit)

        Task { @MainActor in
            self.heartRate = bpm
        }
    }

    // MARK: - Calorie Estimation

    /// Simple MET-based calorie estimate per minute for strength training
    private func updateEstimatedCalories() {
        guard isSessionActive else { return }
        let minutes = elapsedTime / 60.0
        activeCalories = minutes * 5.0
    }

    private func resetState() {
        isSessionActive = false
        isPaused = false
        heartRate = 0
        activeCalories = 0
        elapsedTime = 0
        sessionStartDate = nil
        lastResumeDate = nil
        pausedAccumulated = 0
        workoutBuilder = nil
    }
}
