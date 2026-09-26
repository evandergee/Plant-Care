import SwiftUI
import SwiftData

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // STEP 4: Create the on-device database for Plant and share it with every screen.
        .modelContainer(for: Plant.self)
    }
}
