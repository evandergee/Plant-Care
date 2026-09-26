# PlantCare 🌱

A simple iPhone app for tracking houseplants and when they need water. Built with SwiftUI and SwiftData.

## Features

- Plant list with watering status. Overdue plants are highlighted, and one tap marks a plant as watered.
- Add Plant form with 63 common plants in 7 groups. Picking a plant pre-fills its typical watering schedule and light needs.
- Track light, room, pot type, drainage, soil, fertilizing schedule, and notes.
- Plants are saved on the device with SwiftData, so they persist between launches.
- Green garden theme with light and dark mode.

## Project structure

| File | What it does |
|---|---|
| `MyApp.swift` | App entry point; sets up the SwiftData database |
| `Plant.swift` | Data model (the "plants table"), choice lists, and plant catalog |
| `ContentView.swift` | Main plant list screen |
| `AddPlantView.swift` | Add Plant form |
| `Theme.swift` | Colors, background, and icons |

## Running it

Open `PlantCare.xcodeproj` in Xcode, choose an iPhone simulator, and press Run.
