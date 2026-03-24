import SwiftUI
import SwiftData

@main
struct TuApp: App {
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ChallengeEntry.self,
            GoalItem.self,
            DailyInsightSummary.self,
            EmergencySupportContact.self,
            MediaProgressRecord.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("❌ [SwiftData] Error creando ModelContainer inicial: \(error.localizedDescription)")
            Self.resetSwiftDataStoreFiles()

            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("No se pudo crear ModelContainer tras resetear store: \(error.localizedDescription)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }

    private static func resetSwiftDataStoreFiles() {
        let fileManager = FileManager.default

        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("❌ [SwiftData] No se pudo localizar Application Support para resetear store.")
            return
        }

        let baseStoreURL = appSupportURL.appendingPathComponent("default.store")
        let candidates = [
            baseStoreURL,
            appSupportURL.appendingPathComponent("default.store-wal"),
            appSupportURL.appendingPathComponent("default.store-shm")
        ]

        for url in candidates where fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
                print("🧹 [SwiftData] Store eliminado: \(url.lastPathComponent)")
            } catch {
                print("❌ [SwiftData] No se pudo eliminar \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }
}
