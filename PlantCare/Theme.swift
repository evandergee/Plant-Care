import SwiftUI

// STEP 3: The app's look, in one place.
// Change a color here and it changes everywhere, like a variable in a Power BI theme.

extension Color {
    static let leaf = Color("AccentColor")                            // main green (set in Assets)
    static let leafSoft = Color.green.opacity(0.12)                   // pale green for badges
    static let thirsty = Color(red: 0.85, green: 0.45, blue: 0.20)    // warm orange for "needs water"
}

// A soft green gradient behind every screen. Opacity-based, so it also looks right in Dark Mode.
struct GardenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.green.opacity(0.18), Color.green.opacity(0.04)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// A little icon for each plant group (these are Apple's built-in SF Symbols).
extension PlantCategory {
    var icon: String {
        switch self {
        case .tropical: "leaf.fill"
        case .easyCare: "tree.fill"
        case .succulent: "sun.max.fill"
        case .flowering: "camera.macro"
        case .herb: "carrot.fill"
        case .carnivorous: "ladybug.fill"
        case .airPlant: "wind"
        }
    }
}

extension Plant {
    // Look up this plant's group in the catalog (like a JOIN on species name).
    var category: PlantCategory? {
        speciesCatalog.first { $0.name == speciesName }?.category
    }
    var icon: String {
        category?.icon ?? "leaf"
    }
}
