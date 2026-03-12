import AppIntents

struct KeelFocusFilter: SetFocusFilterIntent {
    static let title: LocalizedStringResource = "Workout Tracking"
    static let description: IntentDescription = "Activates live workout observation in Keel when Fitness Focus is enabled"

    @Parameter(title: "Workout Active", default: false)
    var isWorkoutActive: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "Keel Workout Tracking")
    }

    func perform() async throws -> some IntentResult {
        // Persist to UserDefaults so app can check on foreground
        UserDefaults.standard.set(isWorkoutActive, forKey: FocusState.key)

        // Also post notification for when app is already running
        NotificationCenter.default.post(
            name: .focusFilterDidChange,
            object: nil,
            userInfo: ["isActive": isWorkoutActive]
        )
        return .result()
    }
}

/// Shared keys for Focus Filter state
enum FocusState {
    static let key = "keelExternalWorkoutActive"

    static var isActive: Bool {
        UserDefaults.standard.bool(forKey: key)
    }
}

extension Notification.Name {
    static let focusFilterDidChange = Notification.Name("keelFocusFilterDidChange")
}
