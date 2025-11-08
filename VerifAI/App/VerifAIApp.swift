import SwiftUI
import SwiftData

@main
struct VerifAIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: TaskSettings.self)
        }
    }
}
