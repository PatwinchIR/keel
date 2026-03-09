import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .today
    @State private var plateSettings = PlateSettings()
    @State private var workoutSessionService = WorkoutSessionService()

    enum Tab: String {
        case today, program, progress, settings
    }

    var body: some View {
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
        .tint(K.Colors.accent)
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
