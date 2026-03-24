import SwiftUI
import SwiftData

@main
struct TimesheetApp: App {
    // 1. Create the single source of truth for the entire app
    @StateObject private var subManager = SubscriptionManager()
    
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Job.self,
                TimeEntry.self
            ])

            let config = ModelConfiguration(
                "TimesheetData",
                schema: schema,
                cloudKitDatabase: .private("iCloud.com.florenzo.companshift")
            )

            container = try ModelContainer(for: schema, configurations: [config])
            print("Successfully initialized CloudKit Container")
        } catch {
            fatalError("Could not initialize CloudKit: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 2. Inject the manager into the Environment
                .environmentObject(subManager)
        }
        .modelContainer(container)
    }
}
