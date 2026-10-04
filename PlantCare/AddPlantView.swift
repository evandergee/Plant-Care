import SwiftUI
import PhotosUI

// The plant form, used for BOTH adding a new plant and editing an existing one.
// It opens as a sheet (a card that slides up) from the main list.

struct AddPlantView: View {
    // If a plant is passed in, we're editing it (an UPDATE). If not, we're adding a new one (an INSERT).
    var plant: Plant?
    // "onSave" is a function the main screen gives us, so we can hand a NEW plant back.
    var onSave: (Plant) -> Void
    @Environment(\.dismiss) private var dismiss

    // One @State variable per form field.
    @State private var nickname: String
    @State private var speciesName: String
    @State private var waterEveryDays: Int
    @State private var lastWatered: Date
    @State private var light: LightLevel
    @State private var room: Room
    @State private var potType: PotType
    @State private var hasDrainage: Bool
    @State private var soil: SoilType
    @State private var fertilizes: Bool
    @State private var fertilizeEveryWeeks: Int
    @State private var notes: String
    @State private var showingTypePicker = false   // STEP 15: is the plant type list open?
    @State private var photoData: Data?            // STEP 16: the plant's photo
    @State private var libraryItem: PhotosPickerItem?   // a photo picked from the library
    @State private var showingCamera = false
    @State private var showingPhoto = false        // full-screen viewer

    // Fill the form from the plant being edited, or with defaults for a new one.
    init(plant: Plant? = nil, onSave: @escaping (Plant) -> Void = { _ in }) {
        self.plant = plant
        self.onSave = onSave
        _nickname = State(initialValue: plant?.nickname ?? "")
        _speciesName = State(initialValue: plant?.speciesName ?? "")
        _waterEveryDays = State(initialValue: plant?.waterEveryDays ?? 7)
        _lastWatered = State(initialValue: plant?.lastWatered ?? Date())
        _light = State(initialValue: plant?.light ?? .medium)
        _room = State(initialValue: plant?.room ?? .livingRoom)
        _potType = State(initialValue: plant?.potType ?? .plastic)
        _hasDrainage = State(initialValue: plant?.hasDrainage ?? true)
        _soil = State(initialValue: plant?.soil ?? .standard)
        _fertilizes = State(initialValue: plant?.fertilizes ?? false)
        _fertilizeEveryWeeks = State(initialValue: plant?.fertilizeEveryWeeks ?? 4)
        _notes = State(initialValue: plant?.notes ?? "")
        _photoData = State(initialValue: plant?.photoData)
    }

    // The catalog entry that matches the chosen species, if any.
    private var selectedSpecies: Species? {
        speciesCatalog.first { $0.name == speciesName }
    }

    // Build a Google Images search link for a plant name. URLComponents handles
    // spaces and symbols in the name (like escaping a value before putting it in a query).
    private func photosURL(for name: String) -> URL? {
        var link = URLComponents(string: "https://www.google.com/search")
        link?.queryItems = [
            URLQueryItem(name: "tbm", value: "isch"),          // "isch" = image search
            URLQueryItem(name: "q", value: "\(name) plant"),
        ]
        return link?.url
    }

    // You need either a nickname or a species before you can save.
    private var canSave: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty || !speciesName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // STEP 16: the plant's photo. It's first, so you can photograph a plant
                // and identify it before choosing its type.
                Section {
                    if let photoData, let image = UIImage(data: photoData) {
                        Button {
                            showingPhoto = true
                        } label: {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("View photo")
                    }
                    // Only show the camera button on devices that have a camera.
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showingCamera = true
                        } label: {
                            Label(photoData == nil ? "Take a photo" : "Take a new photo", systemImage: "camera")
                        }
                    }
                    PhotosPicker(selection: $libraryItem, matching: .images) {
                        Label(photoData == nil ? "Choose from library" : "Choose a different photo",
                              systemImage: "photo.on.rectangle")
                    }
                    if photoData != nil {
                        Button(role: .destructive) {
                            photoData = nil
                        } label: {
                            Label("Remove photo", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Photo")
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(photoData == nil
                             ? "Not sure what it is? Add a photo, then tap it to have your iPhone identify the plant."
                             : "Tap the photo to view it full screen and identify the plant.")
                        // Privacy note: the photo is saved inside DeTerra on this phone only.
                        Label("Photos stay on this iPhone. DeTerra never uploads or shares them.",
                              systemImage: "lock.fill")
                    }
                }

                Section {
                    TextField("Nickname (optional)", text: $nickname)

                    // STEP 15: opens the searchable plant list (SpeciesPicker.swift).
                    Button {
                        showingTypePicker = true
                    } label: {
                        HStack {
                            LabeledContent("Type", value: speciesName.isEmpty ? "Other / not listed" : speciesName)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    // STEP 11: open Google Images for the chosen type, so you can
                    // compare the photos with your own plant.
                    if let s = selectedSpecies, let url = photosURL(for: s.name) {
                        Link(destination: url) {
                            Label("See photos of \(s.name)", systemImage: "photo.on.rectangle.angled")
                        }
                    }
                } header: {
                    Text("Plant")
                } footer: {
                    if selectedSpecies == nil {
                        Text("Pick a type to see photos of it and compare with your plant.")
                    }
                }

                Section {
                    Stepper("Every \(waterEveryDays) day\(waterEveryDays == 1 ? "" : "s")",
                            value: $waterEveryDays, in: 1...60)
                    DatePicker("Last watered", selection: $lastWatered,
                               in: ...Date(), displayedComponents: .date)

                    // STEP 12: open this plant's watering history (only when editing).
                    if let plant {
                        NavigationLink {
                            WateringHistoryView(plant: plant)
                        } label: {
                            LabeledContent("Watering history",
                                           value: plant.waterings.isEmpty ? "None yet" : "\(plant.waterings.count)")
                        }
                    }
                } header: {
                    Text("Watering")
                } footer: {
                    if let s = selectedSpecies {
                        Text("Typical for \(s.name): every \(s.waterEveryDays) days. Adjust for your home.")
                    }
                }

                Section {
                    Picker("Light", selection: $light) {
                        ForEach(LightLevel.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Room", selection: $room) {
                        ForEach(Room.allCases) { Text($0.label).tag($0) }
                    }
                } header: {
                    Text("Environment")
                } footer: {
                    // STEP 15: only shows for light that could badly hurt this plant.
                    if let s = selectedSpecies, let warning = lightWarning(for: s, light: light) {
                        Label(warning, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.thirsty)
                    }
                }

                Section("Pot & Soil") {
                    Picker("Pot", selection: $potType) {
                        // STEP 15: the current choices, plus Fabric only if this plant already uses it.
                        ForEach(PotType.choices + (potType == .fabric ? [.fabric] : [])) {
                            Text($0.label).tag($0)
                        }
                    }
                    Toggle("Has drainage hole", isOn: $hasDrainage)
                    Picker("Soil", selection: $soil) {
                        ForEach(SoilType.allCases) { Text($0.label).tag($0) }
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
            .scrollContentBackground(.hidden)   // STEP 3: green garden background
            .background(GardenBackground())
            .navigationTitle(plant == nil ? "Add Plant" : "Edit Plant")
            .navigationDestination(isPresented: $showingTypePicker) {
                SpeciesPicker(selection: $speciesName, isShown: $showingTypePicker)
            }
            // STEP 16: when a library photo is picked, load it, shrink it and keep it.
            .onChange(of: libraryItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        photoData = shrunkPhoto(image)
                    }
                    // Clear the pick, so choosing the same photo again (after removing it) still works.
                    libraryItem = nil
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker { image in photoData = shrunkPhoto(image) }
                    .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showingPhoto) {
                if let photoData, let image = UIImage(data: photoData) {
                    PhotoViewer(image: image)
                }
            }
            // When you pick a species, pre-fill its typical watering and light.
            .onChange(of: speciesName) { _, _ in
                if let s = selectedSpecies {
                    waterEveryDays = s.waterEveryDays
                    light = s.light
                    if s.category == .succulent { soil = .cactus }
                    if s.category == .airPlant { potType = .mounted; hasDrainage = false }
                }
            }
            // STEP 12: if removing a watering on the history screen moves "Last watered"
            // back, show the new date here too (otherwise Save would put the old one back).
            .onChange(of: plant?.lastWatered) { _, newDate in
                if let newDate { lastWatered = newDate }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let cleanNickname = nickname.trimmingCharacters(in: .whitespaces)
        if let plant {
            // Editing: update the existing row. SwiftData saves the changes automatically.
            plant.nickname = cleanNickname
            plant.speciesName = speciesName
            plant.waterEveryDays = waterEveryDays
            plant.lastWatered = lastWatered
            plant.light = light
            plant.room = room
            plant.potType = potType
            plant.hasDrainage = hasDrainage
            plant.soil = soil
            plant.fertilizes = fertilizes
            plant.fertilizeEveryWeeks = fertilizeEveryWeeks
            plant.notes = notes
            plant.photoData = photoData
        } else {
            // Adding: build a new plant and hand it back to the list to insert.
            let newPlant = Plant(
                nickname: cleanNickname,
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
            newPlant.photoData = photoData   // STEP 16
            onSave(newPlant)
        }
    }
}

#Preview {
    AddPlantView()
}
