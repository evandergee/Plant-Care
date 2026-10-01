import Foundation
import SwiftData

// STEP 2: The data model.
// Each "enum" below is a fixed list of choices, like a lookup table in SQL.
// CaseIterable lets a picker loop through every choice automatically.

// Each choice has two parts:
//   - a short, stable KEY (the enum case name), which is what gets saved to the database
//   - a friendly LABEL, which is only for display
// Keeping them separate means you can reword a label later without breaking saved data,
// the same reason you'd join on an ID in SQL instead of on a display name.

enum LightLevel: String, CaseIterable, Identifiable, Codable {
    case low, medium, brightIndirect, fullSun
    var id: String { rawValue }
    var label: String {
        switch self {
        case .low: "Low light"
        case .medium: "Medium / indirect"
        case .brightIndirect: "Bright indirect"
        case .fullSun: "Full sun / direct"
        }
    }
}

enum Room: String, CaseIterable, Identifiable, Codable {
    case livingRoom, bedroom, kitchen, bathroom, office, diningRoom
    case hallway, balcony, outdoorGarden, growTent, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .livingRoom: "Living room"
        case .bedroom: "Bedroom"
        case .kitchen: "Kitchen"
        case .bathroom: "Bathroom"
        case .office: "Office"
        case .diningRoom: "Dining room"
        case .hallway: "Hallway / entry"
        case .balcony: "Balcony / patio"
        case .outdoorGarden: "Outdoor garden"
        case .growTent: "Greenhouse / grow tent"
        case .other: "Other"
        }
    }
}

enum PotType: String, CaseIterable, Identifiable, Codable {
    case plastic, terracotta, ceramic, selfWatering, hanging, fabric, glass, mounted, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .plastic: "Plastic nursery pot"
        case .terracotta: "Terracotta"
        case .ceramic: "Glazed ceramic"
        case .selfWatering: "Self-watering"
        case .hanging: "Hanging basket"
        case .fabric: "Fabric grow bag"
        case .glass: "Glass / terrarium"
        case .mounted: "Mounted / no pot"
        case .other: "Other"
        }
    }
}

enum SoilType: String, CaseIterable, Identifiable, Codable {
    case standard, cactus, aroid, orchidBark, peatMoss, semiHydro, water, gardenSoil, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .standard: "Standard potting mix"
        case .cactus: "Cactus / succulent mix"
        case .aroid: "Chunky aroid mix"
        case .orchidBark: "Orchid bark"
        case .peatMoss: "Peat / sphagnum moss"
        case .semiHydro: "LECA / semi-hydro"
        case .water: "Water (propagation)"
        case .gardenSoil: "Garden soil"
        case .other: "Other"
        }
    }
}

// Plant groups are never saved (they come from the catalog), so display text is fine here.
enum PlantCategory: String, CaseIterable, Identifiable {
    case tropical = "Tropical & Foliage"
    case easyCare = "Low-Maintenance"
    case succulent = "Succulents & Cacti"
    case flowering = "Flowering"
    case herb = "Herbs & Edibles"
    case carnivorous = "Carnivorous"
    case airPlant = "Air Plants"
    var id: String { rawValue }
}

// One entry in the built-in plant catalog, with sensible care defaults.
struct Species: Identifiable, Hashable {
    let name: String
    let emoji: String                  // the little picture shown next to the plant
    let category: PlantCategory
    let waterEveryDays: Int
    let light: LightLevel
    var id: String { name }
}

// The catalog: picking a plant here pre-fills its watering schedule and light.
// These are typical starting points; you can always adjust them in the form.
let speciesCatalog: [Species] = [
    // Tropical & Foliage
    Species(name: "Monstera deliciosa", emoji: "🪴", category: .tropical, waterEveryDays: 7, light: .brightIndirect),
    Species(name: "Golden Pothos", emoji: "🍃", category: .tropical, waterEveryDays: 7, light: .medium),
    Species(name: "Heartleaf Philodendron", emoji: "🍃", category: .tropical, waterEveryDays: 7, light: .medium),
    Species(name: "Philodendron Birkin", emoji: "🪴", category: .tropical, waterEveryDays: 7, light: .brightIndirect),
    Species(name: "Fiddle Leaf Fig", emoji: "🌳", category: .tropical, waterEveryDays: 7, light: .brightIndirect),
    Species(name: "Rubber Plant", emoji: "🌳", category: .tropical, waterEveryDays: 10, light: .brightIndirect),
    Species(name: "Bird of Paradise", emoji: "🌴", category: .tropical, waterEveryDays: 7, light: .brightIndirect),
    Species(name: "Alocasia", emoji: "🪴", category: .tropical, waterEveryDays: 5, light: .brightIndirect),
    Species(name: "Calathea", emoji: "🪴", category: .tropical, waterEveryDays: 5, light: .medium),
    Species(name: "Prayer Plant (Maranta)", emoji: "🪴", category: .tropical, waterEveryDays: 5, light: .medium),
    Species(name: "Anthurium", emoji: "🌺", category: .tropical, waterEveryDays: 7, light: .brightIndirect),
    Species(name: "Croton", emoji: "🍂", category: .tropical, waterEveryDays: 5, light: .brightIndirect),
    Species(name: "Dieffenbachia", emoji: "🪴", category: .tropical, waterEveryDays: 7, light: .medium),
    Species(name: "Arrowhead Plant (Syngonium)", emoji: "🍃", category: .tropical, waterEveryDays: 7, light: .medium),
    Species(name: "Hoya", emoji: "🌸", category: .tropical, waterEveryDays: 10, light: .brightIndirect),
    Species(name: "Spider Plant", emoji: "🌱", category: .tropical, waterEveryDays: 7, light: .medium),
    Species(name: "Dracaena", emoji: "🌴", category: .tropical, waterEveryDays: 10, light: .medium),
    Species(name: "Money Tree", emoji: "🌳", category: .tropical, waterEveryDays: 10, light: .brightIndirect),
    Species(name: "Umbrella Plant (Schefflera)", emoji: "🌳", category: .tropical, waterEveryDays: 10, light: .brightIndirect),
    Species(name: "Parlor Palm", emoji: "🌴", category: .tropical, waterEveryDays: 7, light: .low),
    Species(name: "Areca Palm", emoji: "🌴", category: .tropical, waterEveryDays: 7, light: .brightIndirect),
    Species(name: "English Ivy", emoji: "🍃", category: .tropical, waterEveryDays: 7, light: .medium),
    Species(name: "Boston Fern", emoji: "🌿", category: .tropical, waterEveryDays: 3, light: .medium),
    Species(name: "Bird's Nest Fern", emoji: "🌿", category: .tropical, waterEveryDays: 5, light: .medium),
    Species(name: "Maidenhair Fern", emoji: "🌿", category: .tropical, waterEveryDays: 3, light: .medium),

    // Low-Maintenance
    Species(name: "Snake Plant", emoji: "🪴", category: .easyCare, waterEveryDays: 14, light: .low),
    Species(name: "ZZ Plant", emoji: "🌿", category: .easyCare, waterEveryDays: 14, light: .low),
    Species(name: "Cast Iron Plant", emoji: "🪴", category: .easyCare, waterEveryDays: 10, light: .low),
    Species(name: "Chinese Evergreen", emoji: "🪴", category: .easyCare, waterEveryDays: 10, light: .low),
    Species(name: "Ponytail Palm", emoji: "🌴", category: .easyCare, waterEveryDays: 14, light: .brightIndirect),

    // Succulents & Cacti
    Species(name: "Echeveria", emoji: "🪷", category: .succulent, waterEveryDays: 10, light: .fullSun),
    Species(name: "Jade Plant", emoji: "🪴", category: .succulent, waterEveryDays: 14, light: .fullSun),
    Species(name: "Aloe Vera", emoji: "🌵", category: .succulent, waterEveryDays: 14, light: .fullSun),
    Species(name: "Haworthia", emoji: "🌵", category: .succulent, waterEveryDays: 14, light: .brightIndirect),
    Species(name: "Sempervivum (Hens & Chicks)", emoji: "🪷", category: .succulent, waterEveryDays: 14, light: .fullSun),
    Species(name: "Kalanchoe", emoji: "🌼", category: .succulent, waterEveryDays: 10, light: .brightIndirect),
    Species(name: "String of Pearls", emoji: "🫛", category: .succulent, waterEveryDays: 14, light: .brightIndirect),
    Species(name: "Burro's Tail", emoji: "🌵", category: .succulent, waterEveryDays: 14, light: .fullSun),
    Species(name: "Lithops", emoji: "🪨", category: .succulent, waterEveryDays: 30, light: .fullSun),
    Species(name: "Christmas Cactus", emoji: "🌺", category: .succulent, waterEveryDays: 10, light: .brightIndirect),
    Species(name: "Barrel Cactus", emoji: "🌵", category: .succulent, waterEveryDays: 21, light: .fullSun),
    Species(name: "Bunny Ears Cactus", emoji: "🌵", category: .succulent, waterEveryDays: 21, light: .fullSun),

    // Flowering
    Species(name: "Orchid (Phalaenopsis)", emoji: "🌸", category: .flowering, waterEveryDays: 7, light: .brightIndirect),
    Species(name: "Peace Lily", emoji: "🪷", category: .flowering, waterEveryDays: 5, light: .low),
    Species(name: "African Violet", emoji: "🪻", category: .flowering, waterEveryDays: 5, light: .brightIndirect),
    Species(name: "Bromeliad", emoji: "🍍", category: .flowering, waterEveryDays: 7, light: .brightIndirect),
    Species(name: "Begonia", emoji: "🌸", category: .flowering, waterEveryDays: 5, light: .brightIndirect),
    Species(name: "Gardenia", emoji: "🌼", category: .flowering, waterEveryDays: 5, light: .brightIndirect),
    Species(name: "Hibiscus", emoji: "🌺", category: .flowering, waterEveryDays: 3, light: .fullSun),

    // Herbs & Edibles
    Species(name: "Basil", emoji: "🌿", category: .herb, waterEveryDays: 2, light: .fullSun),
    Species(name: "Mint", emoji: "🍃", category: .herb, waterEveryDays: 2, light: .brightIndirect),
    Species(name: "Parsley", emoji: "🌿", category: .herb, waterEveryDays: 3, light: .fullSun),
    Species(name: "Cilantro", emoji: "🌿", category: .herb, waterEveryDays: 3, light: .fullSun),
    Species(name: "Chives", emoji: "🌱", category: .herb, waterEveryDays: 3, light: .fullSun),
    Species(name: "Rosemary", emoji: "🌿", category: .herb, waterEveryDays: 7, light: .fullSun),
    Species(name: "Thyme", emoji: "🌿", category: .herb, waterEveryDays: 7, light: .fullSun),
    Species(name: "Tomato", emoji: "🍅", category: .herb, waterEveryDays: 2, light: .fullSun),
    Species(name: "Pepper", emoji: "🌶️", category: .herb, waterEveryDays: 3, light: .fullSun),
    Species(name: "Meyer Lemon Tree", emoji: "🍋", category: .herb, waterEveryDays: 7, light: .fullSun),

    // Carnivorous
    Species(name: "Venus Flytrap", emoji: "🪰", category: .carnivorous, waterEveryDays: 2, light: .fullSun),
    Species(name: "Pitcher Plant", emoji: "🪰", category: .carnivorous, waterEveryDays: 2, light: .fullSun),
    Species(name: "Sundew", emoji: "🪰", category: .carnivorous, waterEveryDays: 2, light: .fullSun),

    // Air Plants
    Species(name: "Air Plant (Tillandsia)", emoji: "🌱", category: .airPlant, waterEveryDays: 7, light: .brightIndirect),
]

// STEP 4: Plant is now a SwiftData "@Model", which means it's saved in an on-device
// database. Think of this class as a CREATE TABLE plants (...) statement:
// each property is a column, and each Plant you add is a row.
@Model
final class Plant {
    var nickname: String
    var speciesName: String            // "" means "Other / not listed"
    var waterEveryDays: Int
    var lastWatered: Date
    var light: LightLevel
    var room: Room
    var potType: PotType
    var hasDrainage: Bool
    var soil: SoilType
    var fertilizes: Bool
    var fertilizeEveryWeeks: Int
    var notes: String
    var dateAdded: Date                // used to keep the list in a stable order

    // STEP 12: every watering of this plant (see WateringHistory.swift).
    // .cascade means deleting a plant also deletes its history, like ON DELETE CASCADE in SQL.
    @Relationship(deleteRule: .cascade, inverse: \WateringEvent.plant)
    var waterings: [WateringEvent] = []

    init(nickname: String, speciesName: String, waterEveryDays: Int, lastWatered: Date,
         light: LightLevel, room: Room, potType: PotType, hasDrainage: Bool,
         soil: SoilType, fertilizes: Bool, fertilizeEveryWeeks: Int, notes: String) {
        self.nickname = nickname
        self.speciesName = speciesName
        self.waterEveryDays = waterEveryDays
        self.lastWatered = lastWatered
        self.light = light
        self.room = room
        self.potType = potType
        self.hasDrainage = hasDrainage
        self.soil = soil
        self.fertilizes = fertilizes
        self.fertilizeEveryWeeks = fertilizeEveryWeeks
        self.notes = notes
        self.dateAdded = Date()
    }

    // Computed values are NOT saved; they're worked out from the saved columns.
    var displayName: String {
        if !nickname.isEmpty { return nickname }
        return speciesName.isEmpty ? "Unnamed plant" : speciesName
    }

    // Watering is tracked by calendar DAY, not exact time: a plant watered at 3pm
    // on a 7-day schedule is due all day one week later, not just after 3pm.
    var nextWatering: Date {
        let wateredDay = Calendar.current.startOfDay(for: lastWatered)
        return Calendar.current.date(byAdding: .day, value: waterEveryDays, to: wateredDay) ?? wateredDay
    }

    var needsWater: Bool {
        nextWatering <= Calendar.current.startOfDay(for: Date())
    }
}

// Sample plants, added only the very first time the app opens.
func daysAgo(_ n: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date()
}

func makeSamplePlants() -> [Plant] {
    [
        Plant(nickname: "Monty", speciesName: "Monstera deliciosa", waterEveryDays: 7, lastWatered: daysAgo(8),
              light: .brightIndirect, room: .livingRoom, potType: .plastic, hasDrainage: true,
              soil: .aroid, fertilizes: true, fertilizeEveryWeeks: 4, notes: ""),
        Plant(nickname: "", speciesName: "Snake Plant", waterEveryDays: 14, lastWatered: daysAgo(3),
              light: .low, room: .bedroom, potType: .ceramic, hasDrainage: true,
              soil: .cactus, fertilizes: false, fertilizeEveryWeeks: 8, notes: ""),
        Plant(nickname: "", speciesName: "Echeveria", waterEveryDays: 10, lastWatered: daysAgo(12),
              light: .fullSun, room: .kitchen, potType: .terracotta, hasDrainage: true,
              soil: .cactus, fertilizes: false, fertilizeEveryWeeks: 8, notes: "South window"),
    ]
}
