import SwiftUI
import SwiftData

@main
struct KeelApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Program.self,
            Block.self,
            Workout.self,
            Exercise.self,
            SetLog.self,
            OneRepMax.self,
            BodyComposition.self,
            ProgramTemplate.self,
            CardioLog.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
