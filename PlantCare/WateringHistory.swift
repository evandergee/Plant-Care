import SwiftUI
import SwiftData

// STEP 12: Watering history.
// Until now each plant only remembered its LAST watering. Now every tap of the
// water button also saves a row in a second table, WateringEvent.
// One plant has many watering events: a one-to-many relationship, like a
// "waterings" table with a plant_id foreign key pointing at the plants table.

@Model
final class WateringEvent {
    var date: Date
    var plant: Plant?          // the "foreign key": which plant this watering belongs to

    init(date: Date, plant: Plant? = nil) {
        self.date = date
        self.plant = plant
    }
}

extension Plant {
    // Log a watering: add a row to the history AND update lastWatered,
    // which the schedule and reminders still use.
    // Tapping water twice on the same day counts as one watering, not two.
    func water(on date: Date = Date()) {
        let alreadyLoggedThatDay = waterings.contains {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        if !alreadyLoggedThatDay {
            waterings.append(WateringEvent(date: date))
        }
        lastWatered = date
    }

    // Newest first, like ORDER BY date DESC.
    var wateringsNewestFirst: [WateringEvent] {
        waterings.sorted { $0.date > $1.date }
    }

    // How many days passed between each watering and the one before it.
    // This is what the SQL window function LAG() does: compare each row with the previous row.
    var daysBetweenWaterings: [Int] {
        let days = waterings.map { Calendar.current.startOfDay(for: $0.date) }.sorted()
        return zip(days, days.dropFirst()).compactMap { earlier, later in
            Calendar.current.dateComponents([.day], from: earlier, to: later).day
        }
    }
}

// The history screen: a summary at the top, then every watering, newest first.
struct WateringHistoryView: View {
    let plant: Plant
    @Environment(\.modelContext) private var context

    private var gaps: [Int] { plant.daysBetweenWaterings }

    // Like AVG(gap) in SQL.
    private var averageGap: Double? {
        gaps.isEmpty ? nil : Double(gaps.reduce(0, +)) / Double(gaps.count)
    }

    // "7 days", "6.5 days" or "1 day", instead of "7.0 days".
    private func daysText(_ days: Double) -> String {
        let number = days.rounded() == days ? String(Int(days)) : String(format: "%.1f", days)
        return "\(number) day\(days == 1 ? "" : "s")"
    }

    // Like COUNT(*) WHERE gap <= waterEveryDays.
    private var onTimeCount: Int {
        gaps.filter { $0 <= plant.waterEveryDays }.count
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Times watered", value: "\(plant.waterings.count)")
                if let averageGap {
                    LabeledContent("Average time between", value: daysText(averageGap))
                    LabeledContent("On time", value: "\(onTimeCount) of \(gaps.count)")
                }
            } header: {
                Text("Summary")
            } footer: {
                if !gaps.isEmpty {
                    Text("A watering is on time if it came within \(daysText(Double(plant.waterEveryDays))) of the one before, matching this plant's schedule.")
                }
            }

            Section {
                if plant.waterings.isEmpty {
                    Text("No waterings recorded yet. After you water this plant, tap its water drop button on the My Plants list.")
                        .foregroundStyle(.secondary)
                }
                ForEach(plant.wateringsNewestFirst) { event in
                    Text(event.date, format: .dateTime.weekday(.wide).month().day().year())
                }
                .onDelete(perform: deleteEvents)
            } header: {
                Text("All Waterings")
            } footer: {
                if !plant.waterings.isEmpty {
                    Text("Logged a watering by mistake? Swipe left on the date to remove it.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(GardenBackground())
        .navigationTitle("Watering History")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Remove the swiped rows (DELETE FROM waterings WHERE ...).
    // If the newest watering was removed, "Last watered" goes back to the one before it,
    // so the next due date is right again after fixing a mistaken tap.
    private func deleteEvents(at rows: IndexSet) {
        let events = plant.wateringsNewestFirst
        for row in rows {
            plant.waterings.removeAll { $0 == events[row] }
            context.delete(events[row])
        }
        if let newest = plant.wateringsNewestFirst.first, newest.date < plant.lastWatered {
            plant.lastWatered = newest.date
        }
    }
}
