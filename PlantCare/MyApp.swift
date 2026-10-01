import SwiftUI
import SwiftData

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            // STEP 5: Two tabs along the bottom of the screen.
            TabView {
                ContentView()
                    .tabItem { Label("Plants", systemImage: "leaf.fill") }

                NavigationStack { WeatherView() }
                    .tabItem { Label("Weather", systemImage: "cloud.sun.fill") }
            }
            .tint(Color.leaf)
        }
        // STEP 4: Create the on-device database and share it with every screen.
        // STEP 12 adds a second table, WateringEvent, for the watering history.
        .modelContainer(for: [Plant.self, WateringEvent.self])
    }
}
