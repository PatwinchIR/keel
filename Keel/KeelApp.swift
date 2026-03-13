import SwiftUI
import SwiftData
import CoreData

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
            CardioLog.self,
            WorkoutHistory.self,
            SetHistory.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Migration failed — delete the old store and start fresh.
            // This can happen when new required attributes are added without
            // a schema-level default value.
            let url = modelConfiguration.url
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: .init())
            try? coordinator.destroyPersistentStore(at: url, type: .sqlite)

            // Also remove WAL/SHM sidecar files
            let shmURL = url.deletingPathExtension().appendingPathExtension("sqlite-shm")
            let walURL = url.deletingPathExtension().appendingPathExtension("sqlite-wal")
            try? FileManager.default.removeItem(at: shmURL)
            try? FileManager.default.removeItem(at: walURL)

            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
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
