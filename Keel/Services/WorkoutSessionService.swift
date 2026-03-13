import Foundation
import HealthKit

@Observable
final class WorkoutSessionService: NSObject, @unchecked Sendable {
    private let healthStore: HKHealthStore
    private var workoutBuilder: HKWorkoutBuilder?
    private var hrQuery: HKAnchoredObjectQuery?
    private var calorieQuery: HKAnchoredObjectQuery?
    private var timer: Timer?
    private var sessionStartDate: Date?

    var isSessionActive = false
    var isPaused = false
    var heartRate: Double = 0
    var activeCalories: Double = 0
    var elapsedTime: TimeInterval = 0
    var sessionMode: SessionMode = .none

    private var pausedAccumulated: TimeInterval = 0
    private var lastResumeDate: Date?

    enum SessionMode {
        case none
        case `internal`
        case external
    }

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
        super.init()
    }

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

    // MARK: - Focus Filter Observation

    func setupFocusFilterObservation() {
        // Listen for Focus Filter intent notifications
        NotificationCenter.default.addObserver(
            forName: .focusFilterDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let isActive = notification.userInfo?["isActive"] as? Bool ?? false
            if isActive {
                self?.startExternalObservation()
            } else {
                self?.stopExternalObservation()
            }
        }
    }

    /// Called on app foreground — only stop stale external sessions, never start new ones.
    /// Starting is handled exclusively by the Focus Filter intent notification.
    func checkFocusState() {
        if !FocusFilterState.isActive && sessionMode == .external {
            stopExternalObservation()
        }
    }

    // MARK: - Internal Session Lifecycle

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
        activeCalories = 0

        Task {
            do {
                try await workoutBuilder?.beginCollection(at: now)
            } catch {
                print("Failed to begin workout collection: \(error)")
            }
        }

        sessionMode = .internal
        isSessionActive = true
        isPaused = false
        startTimer()
        startHeartRateQuery(from: now)
        startCalorieQuery(from: now)
    }

    func pauseSession() {
        guard isSessionActive, !isPaused, sessionMode == .internal else { return }
        isPaused = true
        if let resume = lastResumeDate {
            pausedAccumulated += Date().timeIntervalSince(resume)
        }
        lastResumeDate = nil
        stopTimer()
    }

    func resumeSession() {
        guard isSessionActive, isPaused, sessionMode == .internal else { return }
        isPaused = false
        lastResumeDate = Date()
        startTimer()
    }

    func endSession() {
        guard isSessionActive else { return }

        if sessionMode == .external {
            stopExternalObservation()
            return
        }

        stopTimer()
        stopHeartRateQuery()
        stopCalorieQuery()

        // Final elapsed calculation
        if !isPaused, let resume = lastResumeDate {
            pausedAccumulated += Date().timeIntervalSince(resume)
        }
        elapsedTime = pausedAccumulated

        let endDate = Date()

        Task {
            do {
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

    // MARK: - External Session (Focus Filter)

    private func startExternalObservation() {
        guard !isSessionActive else { return }

        let now = Date()
        sessionStartDate = now
        lastResumeDate = now
        pausedAccumulated = 0
        activeCalories = 0

        sessionMode = .external
        isSessionActive = true
        isPaused = false
        startTimer()
        startHeartRateQuery(from: now)
        startCalorieQuery(from: now)
    }

    private func stopExternalObservation() {
        guard sessionMode == .external else { return }
        stopTimer()
        stopHeartRateQuery()
        stopCalorieQuery()
        // Clear persisted focus state so it doesn't restart on next foreground
        UserDefaults.standard.set(false, forKey: FocusFilterState.key)
        resetState()
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

    // MARK: - Real Calorie Observation

    private func startCalorieQuery(from startDate: Date) {
        guard let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)

        calorieQuery = HKAnchoredObjectQuery(
            type: calType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processCalorieSamples(samples)
        }

        calorieQuery?.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processCalorieSamples(samples)
        }

        if let calorieQuery {
            healthStore.execute(calorieQuery)
        }
    }

    private func stopCalorieQuery() {
        if let calorieQuery {
            healthStore.stop(calorieQuery)
        }
        calorieQuery = nil
    }

    private func processCalorieSamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample] else { return }

        let total = quantitySamples.reduce(0.0) { sum, sample in
            sum + sample.quantity.doubleValue(for: .kilocalorie())
        }

        guard total > 0 else { return }

        Task { @MainActor in
            self.activeCalories += total
        }
    }

    // MARK: - Reset

    private func resetState() {
        isSessionActive = false
        isPaused = false
        sessionMode = .none
        heartRate = 0
        activeCalories = 0
        elapsedTime = 0
        sessionStartDate = nil
        lastResumeDate = nil
        pausedAccumulated = 0
        workoutBuilder = nil
    }
}
