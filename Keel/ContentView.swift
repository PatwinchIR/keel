import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .today
    @State private var plateSettings = PlateSettings()
    @State private var restDaySettings = RestDaySettings()
    @State private var healthKitService: HealthKitService
    @State private var workoutSessionService: WorkoutSessionService

    enum Tab: String {
        case today, program, progress, settings
    }

    init() {
        let hks = HealthKitService()
        _healthKitService = State(initialValue: hks)
        _workoutSessionService = State(initialValue: WorkoutSessionService(healthStore: hks.healthStore))
    }

    var body: some View {
        VStack(spacing: 0) {
            if workoutSessionService.isSessionActive {
                LiveWorkoutBanner(
                    workoutService: workoutSessionService,
                    healthKitService: healthKitService
                )
            }

            TabView(selection: $selectedTab) {
            TodayView(workoutSession: workoutSessionService)
                .tabItem {
                    Label("Today", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(Tab.today)

            ProgramOverviewView()
                .tabItem {
                    Label("Program", systemImage: "calendar")
                }
                .tag(Tab.program)

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.xyaxis.line")
                }
                .tag(Tab.progress)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .environment(plateSettings)
        .environment(restDaySettings)
        .environment(healthKitService)
        .tint(K.Colors.accent)
        .task {
            await healthKitService.requestAuthorization()
            workoutSessionService.setupFocusFilterObservation()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                workoutSessionService.checkFocusState()
                let service = ProgramService(modelContext: modelContext)
                service.migrateExerciseNames()
                service.migrateLockedOneRepMaxes()
                service.checkWeekTransition()
            }
        }
        .onChange(of: workoutSessionService.isSessionActive) { _, isActive in
            UIApplication.shared.isIdleTimerDisabled = isActive
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(K.Colors.surface)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(K.Colors.tertiary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(K.Colors.tertiary)]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(K.Colors.accent)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(K.Colors.accent)]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        }
    }
}
