import SwiftUI

// STEP 6: Weather-aware watering tips.
// The idea: look at the next few days of forecast and, for OUTDOOR plants,
// suggest skipping water when rain is coming, checking early when it's hot,
// and protecting them when frost is coming. Indoor plants don't feel the
// weather much, so they get no tip.

// One tip to show under a plant: the words, an icon, and a color.
struct WateringTip {
    let text: String
    let icon: String   // an SF Symbol name
    let color: Color
}

extension Plant {
    // Balcony and garden plants are the ones the weather actually reaches.
    var isOutdoors: Bool {
        room == .outdoorGarden || room == .balcony
    }
}

// The "rules engine". Think of it like a SQL CASE WHEN: the first rule that
// matches wins, so the most urgent one (frost) goes first.
func wateringTip(for plant: Plant, forecast: Forecast) -> WateringTip? {
    guard plant.isOutdoors else { return nil }

    let daily = forecast.daily
    let nextTwoDays = daily.time.indices.prefix(2)     // today + tomorrow
    let nextThreeDays = daily.time.indices.prefix(3)

    // Rule 1: frost. Coldest low in the next 3 days at or below 35°F.
    let coldest = nextThreeDays.map { daily.temperature_2m_min[$0] }.min() ?? 50
    if coldest <= 35 {
        return WateringTip(text: "Frost risk (\(Int(coldest))°). Cover it or bring it in",
                           icon: "snowflake", color: .blue)
    }

    // Rule 2: rain. A quarter inch or more expected today + tomorrow (like SUM()).
    let rain = nextTwoDays.map { daily.precipitation_sum[$0] }.reduce(0, +)
    if rain >= 0.25 {
        return WateringTip(text: "Rain coming (\(String(format: "%.1f", rain))\"). Skip watering",
                           icon: "cloud.rain.fill", color: .blue)
    }

    // Rule 3: heat. Hottest high in the next 3 days at or above 90°F.
    let hottest = nextThreeDays.map { daily.temperature_2m_max[$0] }.max() ?? 70
    if hottest >= 90 {
        return WateringTip(text: "Hot days ahead (\(Int(hottest))°). Check the soil early",
                           icon: "sun.max.fill", color: .orange)
    }

    return nil   // nothing unusual, so stick to the normal schedule
}
