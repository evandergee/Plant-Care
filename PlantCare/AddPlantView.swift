import SwiftUI

// STEP 2: The "Add Plant" form.
// It opens as a sheet (a card that slides up) from the main list.

struct AddPlantView: View {
    // "onSave" is a function the main screen gives us, so we can hand the new plant back.
    var onSave: (Plant) -> Void
    @Environment(\.dismiss) private var dismiss

    // One @State variable per form field.
    @State private var nickname = ""
    @State private var speciesName = ""
    @State private var waterEveryDays = 7
    @State private var lastWatered = Date()
    @State private var light: LightLevel = .medium
    @State private var room: Room = .livingRoom
    @State private var potType: PotType = .plastic
    @State private var hasDrainage = true
    @State private var soil: SoilType = .standard
    @State private var fertilizes = false
    @State private var fertilizeEveryWeeks = 4
    @State private var notes = ""

    // The catalog entry that matches the chosen species, if any.
    private var selectedSpecies: Species? {
        speciesCatalog.first { $0.name == speciesName }
    }

    // You need either a nickname or a species before you can save.
    private var canSave: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty || !speciesName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plant") {
                    TextField("Nickname (optional)", text: $nickname)

                    Picker("Type", selection: $speciesName) {
                        Text("Other / not listed").tag("")
                        // One group per category, like GROUP BY category in SQL.
                        ForEach(PlantCategory.allCases) { category in
                            Section(category.rawValue) {
                                ForEach(speciesCatalog.filter { $0.category == category }) { species in
                                    Text(species.name).tag(species.name)
                                }
                            }
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.navigationLink)   // opens a full scrollable list on iPhone
                    #endif
                }

                Section {
                    Stepper("Every \(waterEveryDays) day\(waterEveryDays == 1 ? "" : "s")",
                            value: $waterEveryDays, in: 1...60)
                    DatePicker("Last watered", selection: $lastWatered,
                               in: ...Date(), displayedComponents: .date)
                } header: {
                    Text("Watering")
                } footer: {
                    if let s = selectedSpecies {
                        Text("Typical for \(s.name): every \(s.waterEveryDays) days. Adjust for your home.")
                    }
                }

                Section("Environment") {
                    Picker("Light", selection: $light) {
                        ForEach(LightLevel.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Room", selection: $room) {
                        ForEach(Room.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Pot & Soil") {
                    Picker("Pot", selection: $potType) {
                        ForEach(PotType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Toggle("Has drainage hole", isOn: $hasDrainage)
                    Picker("Soil", selection: $soil) {
                        ForEach(SoilType.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Fertilizing") {
                    Toggle("I fertilize this plant", isOn: $fertilizes)
                    if fertilizes {
                        Stepper("Every \(fertilizeEveryWeeks) week\(fertilizeEveryWeeks == 1 ? "" : "s")",
                                value: $fertilizeEveryWeeks, in: 1...26)
                    }
                }

                Section("Notes") {
                    TextField("Anything to remember…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Plant")
            // When you pick a species, pre-fill its typical watering and light.
            .onChange(of: speciesName) { _, _ in
                if let s = selectedSpecies {
                    waterEveryDays = s.waterEveryDays
                    light = s.light
                    if s.category == .succulent { soil = .cactus }
                    if s.category == .airPlant { potType = .mounted; hasDrainage = false }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let plant = Plant(
                            nickname: nickname.trimmingCharacters(in: .whitespaces),
                            speciesName: speciesName,
                            waterEveryDays: waterEveryDays,
                            lastWatered: lastWatered,
                            light: light,
                            room: room,
                            potType: potType,
                            hasDrainage: hasDrainage,
                            soil: soil,
                            fertilizes: fertilizes,
                            fertilizeEveryWeeks: fertilizeEveryWeeks,
                            notes: notes
                        )
                        onSave(plant)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    AddPlantView { _ in }
}
