import SwiftUI
import SwiftData

@main
struct VerifAIApp: App {
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
