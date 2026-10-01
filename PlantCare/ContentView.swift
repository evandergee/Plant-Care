import SwiftUI
import SwiftData
import CoreLocation

// The main screen: your list of plants.
// STEP 3 gives it a green garden look: gradient background, card-style rows,
// an emoji per plant, and a colored watering badge.

struct ContentView: View {
    // STEP 4: @Query reads plants from the database, like
    // SELECT * FROM plants ORDER BY dateAdded. The list updates automatically.
    @Query(sort: \Plant.dateAdded) private var plants: [Plant]
    @Environment(\.modelContext) private var context   // used to INSERT and DELETE
    @AppStorage("didAddSamples") private var didAddSamples = false
    @State private var showingAddPlant = false
    @State private var editingPlant: Plant?          // the plant whose edit form is open
    @State private var forecast: Forecast?           // STEP 6: used for tips and the weather badge
    @State private var weatherFailed = false         // true if the forecast couldn't load
    @State private var alertsAllowed = true          // STEP 10: did the user allow notifications?

    // STEP 8: the place chosen on the Weather tab (same saved keys, so they stay in sync).
    @AppStorage("placeName") private var placeName = "St. Louis"
    @AppStorage("placeLat") private var placeLat = stLouis.latitude
    @AppStorage("placeLon") private var placeLon = stLouis.longitude

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
                        PlantRow(plant: plant,
                                 tip: forecast.flatMap { wateringTip(for: plant, forecast: $0) })
                            .contentShape(Rectangle())
                            .onTapGesture { editingPlant = plant }   // tap a row to edit it
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
                } footer: {
                    // STEP 10: a short note under the list explaining how reminders work.
                    if !plants.isEmpty {
                        Label(alertsAllowed
                              ? "Each plant has its own schedule. You'll get a reminder at 9 AM on the day it's due. Tap a plant to change how often."
                              : "Reminders are off. Turn on notifications for Project Gaia in Settings to get alerts when plants are due.",
                              systemImage: alertsAllowed ? "bell.fill" : "bell.slash.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
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
                // STEP 7: current temp and humidity in the top-left corner.
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 10) {
                        if let current = forecast?.current {
                            Label("\(Int(current.temperature_2m))°", systemImage: "thermometer.medium")
                            Label("\(Int(current.relative_humidity_2m))%", systemImage: "humidity")
                        } else if weatherFailed {
                            Image(systemName: "cloud.slash")   // no internet / weather down
                        } else {
                            ProgressView()                     // still loading
                        }
                    }
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize()
                    .padding(.horizontal, 6)
                    .accessibilityLabel("Current weather at \(placeName)")
                }
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
                    newPlant.water(on: newPlant.lastWatered)   // first entry in its history
                }
            }
            .sheet(item: $editingPlant) { plant in
                AddPlantView(plant: plant)   // same form, filled in with this plant
            }
            // STEP 8: load the forecast for the saved place, and reload whenever it changes.
            .task(id: "\(placeLat),\(placeLon)") {
                let place = CLLocationCoordinate2D(latitude: placeLat, longitude: placeLon)
                forecast = try? await fetchForecast(at: place)
                weatherFailed = (forecast == nil)
            }
            // STEP 9: re-plan the watering alerts whenever a plant's name or due date
            // changes, or a plant is added or deleted. The "id" is a list of those values;
            // when it changes, this block runs again.
            .task(id: plants.map { "\($0.displayName)|\($0.room.label)|\($0.nextWatering.timeIntervalSince1970)" }) {
                alertsAllowed = await WateringAlerts.reschedule(plants)
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
    var tip: WateringTip? = nil  // STEP 6: weather tip, if there is one

    var body: some View {
        HStack(spacing: 14) {
            // Round badge with the plant's own emoji
            Text(plant.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.leafSoft))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(plant.displayName)
                    .font(.headline)

                Text([plant.nickname.isEmpty ? "" : plant.speciesName, plant.room.label]
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

                // STEP 6: the weather tip, only for outdoor plants when something's up
                if let tip {
                    Label(tip.text, systemImage: tip.icon)
                        .font(.caption)
                        .foregroundStyle(tip.color)
                }
            }

            Spacer()

            // Water button
            Button {
                withAnimation(.spring) {
                    plant.water()   // STEP 12: logs it in the history too
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
        .modelContainer(for: [Plant.self, WateringEvent.self], inMemory: true)
}
