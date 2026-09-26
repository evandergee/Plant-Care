import SwiftUI
import SwiftData

// The main screen: your list of plants.
// STEP 3 gives it a green garden look: gradient background, card-style rows,
// an icon per plant group, and a colored watering badge.

struct ContentView: View {
    // STEP 4: @Query reads plants from the database, like
    // SELECT * FROM plants ORDER BY dateAdded. The list updates automatically.
    @Query(sort: \Plant.dateAdded) private var plants: [Plant]
    @Environment(\.modelContext) private var context   // used to INSERT and DELETE
    @AppStorage("didAddSamples") private var didAddSamples = false
    @State private var showingAddPlant = false

    // How many plants are thirsty right now (like COUNT(*) WHERE needs_water).
    private var thirstyCount: Int {
        plants.filter(\.needsWater).count
    }

    var body: some View {
        NavigationStack {
            List {
                // Summary banner at the top
                if !plants.isEmpty {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: thirstyCount > 0 ? "drop.fill" : "checkmark.seal.fill")
                                .font(.title2)
                                .foregroundStyle(thirstyCount > 0 ? Color.thirsty : Color.leaf)
                            Text(thirstyCount > 0
                                 ? "\(thirstyCount) plant\(thirstyCount == 1 ? "" : "s") need\(thirstyCount == 1 ? "s" : "") water today"
                                 : "Everyone's watered. Nice work!")
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.leafSoft)
                }

                Section {
                    ForEach(plants) { plant in
                        PlantRow(plant: plant)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.background.opacity(0.85))
                                    .padding(.vertical, 3)
                            )
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { rows in
                        for row in rows {
                            context.delete(plants[row])   // DELETE FROM plants WHERE ...
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)     // hide the default grey so our gradient shows
            .background(GardenBackground())
            .overlay {
                if plants.isEmpty {
                    ContentUnavailableView("No plants yet",
                                           systemImage: "leaf",
                                           description: Text("Tap + to add your first plant."))
                }
            }
            .navigationTitle("My Plants 🌱")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPlant = true
                    } label: {
                        Label("Add Plant", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlant) {
                AddPlantView { newPlant in
                    context.insert(newPlant)   // INSERT INTO plants ...
                }
            }
            // First launch only: add the sample plants so the list isn't empty.
            .onAppear {
                if !didAddSamples {
                    makeSamplePlants().forEach { context.insert($0) }
                    didAddSamples = true
                }
            }
        }
    }
}

// One row in the list, pulled into its own view to keep things tidy.
struct PlantRow: View {
    @Bindable var plant: Plant   // a saved plant; changes are written to the database

    var body: some View {
        HStack(spacing: 14) {
            // Round icon badge
            Image(systemName: plant.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.leaf.gradient))

            VStack(alignment: .leading, spacing: 4) {
                Text(plant.displayName)
                    .font(.headline)

                Text([plant.nickname.isEmpty ? "" : plant.speciesName, plant.room.rawValue]
                        .filter { !$0.isEmpty }
                        .joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Status pill: orange if thirsty, green otherwise
                Label(plant.needsWater
                      ? "Needs water"
                      : plant.nextWatering.formatted(.dateTime.month(.abbreviated).day()),
                      systemImage: plant.needsWater ? "exclamationmark.circle.fill" : "calendar")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(plant.needsWater ? Color.thirsty : Color.leaf)
                    .background(Capsule().fill((plant.needsWater ? Color.thirsty : Color.leaf).opacity(0.15)))
            }

            Spacer()

            // Water button
            Button {
                withAnimation(.spring) {
                    plant.lastWatered = Date()
                }
            } label: {
                Image(systemName: "drop.fill")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .tint(plant.needsWater ? Color.thirsty : Color.leaf)
            .accessibilityLabel("Mark \(plant.displayName) as watered")
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Plant.self, inMemory: true)
}
