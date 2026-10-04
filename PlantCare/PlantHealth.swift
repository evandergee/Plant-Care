import SwiftUI

// STEP 18: Plant Health ("Something wrong?").
// You pick a symptom, and the app lists the likely causes and what to do.
// It works offline and for free: there's no photo service. The causes are common
// houseplant problems, ranked using this plant's own settings (watering, light,
// drainage), like a scoring rule in SQL: each cause gets points, then ORDER BY score DESC.

enum Symptom: String, CaseIterable, Identifiable {
    case yellowLeaves, brownTips, drooping, mushyStem, spots
    case droppingLeaves, leggy, scorched, pests, moldOnSoil

    var id: String { rawValue }

    var label: String {
        switch self {
        case .yellowLeaves: "Yellow leaves"
        case .brownTips: "Brown, crispy tips or edges"
        case .drooping: "Drooping or wilting"
        case .mushyStem: "Soft, mushy stem or base"
        case .spots: "Brown or black spots"
        case .droppingLeaves: "Leaves falling off"
        case .leggy: "Long, stretched stems"
        case .scorched: "Pale or bleached patches"
        case .pests: "Tiny bugs, webs, or sticky leaves"
        case .moldOnSoil: "White fuzz or mold on the soil"
        }
    }

    var icon: String {
        switch self {
        case .yellowLeaves: "leaf"
        case .brownTips: "scissors"
        case .drooping: "arrow.down.right"
        case .mushyStem: "drop.triangle"
        case .spots: "circle.dotted"
        case .droppingLeaves: "arrow.down.circle"
        case .leggy: "arrow.up.and.down"
        case .scorched: "sun.max"
        case .pests: "ladybug"
        case .moldOnSoil: "aqi.medium"
        }
    }

    // Words for the Google Images search, e.g. "Monstera deliciosa yellow leaves".
    var searchTerm: String {
        switch self {
        case .yellowLeaves: "yellow leaves"
        case .brownTips: "brown leaf tips"
        case .drooping: "drooping leaves"
        case .mushyStem: "root rot"
        case .spots: "leaf spots"
        case .droppingLeaves: "dropping leaves"
        case .leggy: "leggy growth"
        case .scorched: "sunburn leaves"
        case .pests: "pests"
        case .moldOnSoil: "mold on soil"
        }
    }
}

// One possible cause: what it is, what to do, and (when this plant's settings
// point to it) why it's likely.
struct Cause: Identifiable {
    let title: String
    let fix: String
    var reasons: [String] = []
    var score: Int
    var id: String { title }
}

// Facts about the plant that help rank the causes.
private struct PlantFacts {
    let overdueDays: Int          // days past its watering date (0 if not overdue)
    let watersOften: Bool         // watered much more often than is typical for its type
    let noDrainage: Bool
    let lightTooLow: Bool         // set well below the light its type needs
    let lightTooHigh: Bool        // shade plant in sun, or well above its type's light
    let isSucculent: Bool
    let fertilizes: Bool

    init(_ plant: Plant) {
        let species = plant.species
        overdueDays = max(0, -plant.daysUntilWatering)
        if let typical = species?.waterEveryDays {
            watersOften = Double(plant.waterEveryDays) < Double(typical) * 0.6
        } else {
            watersOften = false
        }
        noDrainage = !plant.hasDrainage
        let rank: (LightLevel) -> Int = { [.low, .medium, .brightIndirect, .fullSun].firstIndex(of: $0) ?? 1 }
        if let species {
            lightTooLow = rank(species.light) - rank(plant.light) >= 2
            // Only flag direct sun for plants that actually burn in it. Many "low light"
            // plants (like Snake Plant) handle sun fine; they just tolerate shade too.
            lightTooHigh = plant.light == .fullSun
                && (burnsInDirectSun.contains(species.name) || species.light == .medium)
        } else {
            lightTooLow = false
            lightTooHigh = false
        }
        isSucculent = species?.category == .succulent
        fertilizes = plant.fertilizes
    }
}

// The rules. Each cause starts with a base score for how common it is, and gains
// points when this plant's settings point to it.
func likelyCauses(of symptom: Symptom, for plant: Plant) -> [Cause] {
    let f = PlantFacts(plant)
    let overdue = "It's \(f.overdueDays) day\(f.overdueDays == 1 ? "" : "s") past its watering date."
    let noDrain = "Its pot has no drainage hole, so extra water can't escape."
    let often = "It's watered more often than is typical for its type."
    let dark = "Its light is set lower than its type needs."
    let bright = "Its light is set brighter than its type likes."

    func cause(_ title: String, _ fix: String, base: Int, _ boosts: [(Bool, Int, String)] = []) -> Cause {
        var c = Cause(title: title, fix: fix, score: base)
        for (applies, points, reason) in boosts where applies {
            c.score += points
            c.reasons.append(reason)
        }
        return c
    }

    let causes: [Cause]
    switch symptom {
    case .yellowLeaves:
        causes = [
            cause("Too much water", "Let the top inch or two of soil dry out before watering again, and make sure water can drain out of the pot.",
                  base: 3, [(f.noDrainage, 3, noDrain), (f.watersOften, 2, often), (f.isSucculent, 1, "Succulents are very sensitive to too much water.")]),
            cause("Too little water", "Water thoroughly until water runs out the bottom, then keep to its schedule.",
                  base: 2, [(f.overdueDays > 0, 3, overdue)]),
            cause("Not enough light", "Move it closer to a window or to a brighter room.",
                  base: 1, [(f.lightTooLow, 3, dark)]),
            cause("Normal aging", "If it's only one or two of the oldest, lowest leaves, that's normal. Remove them once they're fully yellow.",
                  base: 2),
            cause("Needs nutrients", "Feed it with a balanced houseplant fertilizer during spring and summer.",
                  base: 1, [(!f.fertilizes, 1, "It isn't set as fertilized.")]),
        ]
    case .brownTips:
        causes = [
            cause("Dry air", "Group plants together, use a tray of wet pebbles under the pot, or run a humidifier nearby.",
                  base: 3),
            cause("Too little water", "Water thoroughly and keep to its schedule. Brown tips won't turn green again, but new leaves will be healthy.",
                  base: 2, [(f.overdueDays > 0, 3, overdue)]),
            cause("Too much fertilizer", "Run plenty of water through the soil to flush out built-up salts, and fertilize less often.",
                  base: 1, [(f.fertilizes, 1, "It's set as fertilized.")]),
            cause("Too much direct sun", "Move it out of direct sun, or filter the light with a sheer curtain.",
                  base: 1, [(f.lightTooHigh, 3, bright)]),
        ]
    case .drooping:
        causes = [
            cause("Thirsty", "Water thoroughly. A thirsty plant usually perks up within a day.",
                  base: 3, [(f.overdueDays > 0, 3, overdue)]),
            cause("Waterlogged roots", "If the soil is soggy, stop watering and let it dry out. Check that the pot drains.",
                  base: 2, [(f.noDrainage, 3, noDrain), (f.watersOften, 2, often)]),
            cause("Too hot or too cold", "Keep it away from heaters, air conditioning vents, and cold windows.",
                  base: 1),
            cause("Recently moved or repotted", "Give it a week or two to settle in. Keep its care steady meanwhile.",
                  base: 1),
        ]
    case .mushyStem:
        causes = [
            cause("Root or stem rot from too much water", "Take it out of the pot, cut away black or mushy roots, and repot in fresh, dry soil in a pot with drainage. Water less often from now on.",
                  base: 5, [(f.noDrainage, 2, noDrain), (f.watersOften, 2, often)]),
            cause("Cold damage", "Move it somewhere warmer, away from cold windows and drafts.",
                  base: 1),
        ]
    case .spots:
        causes = [
            cause("Leaf spot disease", "Remove the spotted leaves, water the soil instead of the leaves, and give it more air flow.",
                  base: 3, [(f.watersOften, 1, often)]),
            cause("Sunburn", "Move it out of harsh direct sun.",
                  base: 1, [(f.lightTooHigh, 3, bright)]),
            cause("Pests", "Check the undersides of leaves for tiny bugs. See \"Tiny bugs, webs, or sticky leaves\" for what to do.",
                  base: 1),
        ]
    case .droppingLeaves:
        causes = [
            cause("A sudden change", "Moving, drafts, or temperature swings often cause leaf drop. Keep it in one spot and its care steady.",
                  base: 3),
            cause("Watering problems", "Check the soil: water if it's bone dry, let it dry out if it's soggy.",
                  base: 2, [(f.overdueDays > 0, 2, overdue), (f.noDrainage, 2, noDrain)]),
            cause("Not enough light", "Move it somewhere brighter.",
                  base: 1, [(f.lightTooLow, 3, dark)]),
        ]
    case .leggy:
        causes = [
            cause("Not enough light", "Move it somewhere brighter and turn the pot every week or so. Trim long stems to encourage bushier growth.",
                  base: 4, [(f.lightTooLow, 3, dark)]),
            cause("Normal growth", "Some plants naturally grow long, trailing stems. Trim them if you'd like a fuller shape.",
                  base: 1),
        ]
    case .scorched:
        causes = [
            cause("Too much direct sun", "Move it out of direct sun, or filter the light with a sheer curtain.",
                  base: 3, [(f.lightTooHigh, 3, bright)]),
            cause("Moved into sun too quickly", "Plants need time to adjust to brighter light. Move it back, then increase light gradually over a couple of weeks.",
                  base: 2),
        ]
    case .pests:
        causes = [
            cause("Spider mites", "Look for fine webbing and tiny speckles. Rinse the leaves in the shower, then treat with insecticidal soap. Keep it away from other plants.",
                  base: 2),
            cause("Mealybugs", "Look for white, cottony clumps. Dab them with a cotton swab dipped in rubbing alcohol, and repeat weekly.",
                  base: 2),
            cause("Fungus gnats", "Tiny flies around the soil come from soil that stays wet. Let the soil dry out more between waterings and use yellow sticky traps.",
                  base: 2, [(f.watersOften, 2, often), (f.noDrainage, 1, noDrain)]),
            cause("Scale or aphids", "Look for small bumps on stems or clusters of tiny green or black bugs. Wipe them off and treat with insecticidal soap.",
                  base: 1),
        ]
    case .moldOnSoil:
        causes = [
            cause("Soil staying too wet", "Scrape off the moldy layer, let the soil dry out, and water less often. More air flow helps too. It's usually harmless to the plant.",
                  base: 4, [(f.noDrainage, 2, noDrain), (f.watersOften, 2, often)]),
        ]
    }
    return causes.sorted { $0.score > $1.score }   // ORDER BY score DESC
}

// Screen 1: what do you see?
struct PlantHealthView: View {
    let plant: Plant

    var body: some View {
        List {
            Section {
                ForEach(Symptom.allCases) { symptom in
                    NavigationLink {
                        SymptomResultView(plant: plant, symptom: symptom)
                    } label: {
                        Label(symptom.label, systemImage: symptom.icon)
                    }
                }
            } header: {
                Text("What Do You See?")
            } footer: {
                Text("Pick the closest match. You'll get likely causes for \(plant.displayName), ranked using its watering, light, and pot settings.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(GardenBackground())
        .navigationTitle("Plant Health")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Screen 2: likely causes and what to do.
struct SymptomResultView: View {
    let plant: Plant
    let symptom: Symptom

    private var causes: [Cause] { likelyCauses(of: symptom, for: plant) }

    // Google Images search, e.g. "Monstera deliciosa yellow leaves".
    private var photosURL: URL? {
        let name = plant.speciesName.isEmpty ? "houseplant" : plant.speciesName
        var link = URLComponents(string: "https://www.google.com/search")
        link?.queryItems = [
            URLQueryItem(name: "tbm", value: "isch"),
            URLQueryItem(name: "q", value: "\(name) \(symptom.searchTerm)"),
        ]
        return link?.url
    }

    var body: some View {
        List {
            ForEach(Array(causes.enumerated()), id: \.element.id) { index, cause in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        if index == 0 {
                            Text("Most likely")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .foregroundStyle(Color.leaf)
                                .background(Capsule().fill(Color.leaf.opacity(0.15)))
                        }
                        Text(cause.title)
                            .font(.headline)
                        ForEach(cause.reasons, id: \.self) { reason in
                            Label(reason, systemImage: "info.circle")
                                .font(.caption)
                                .foregroundStyle(Color.thirsty)
                        }
                        Text(cause.fix)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                if let photosURL {
                    Link(destination: photosURL) {
                        Label("See photos of \(symptom.searchTerm)", systemImage: "photo.on.rectangle.angled")
                    }
                }
            } footer: {
                Text("General guidance based on common causes and this plant's settings. The app can't see your plant, so check the soil, roots, and leaves to confirm.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(GardenBackground())
        .navigationTitle(symptom.label)
        .navigationBarTitleDisplayMode(.inline)
    }
}
