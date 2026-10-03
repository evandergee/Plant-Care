import SwiftUI

// STEP 15: The plant type list, with a search box.
// It replaces the plain picker, which made you scroll through 100+ names.
// Searching works like SQL's WHERE name LIKE '%text%', ignoring upper/lower case.

struct SpeciesPicker: View {
    @Binding var selection: String          // the chosen species name ("" = Other / not listed)
    @Binding var isShown: Bool              // set to false to go back to the form
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool   // is the keyboard in the search box?

    // The catalog rows that match the search (all of them when the box is empty).
    private var matches: [Species] {
        let text = searchText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return speciesCatalog }
        return speciesCatalog.filter { $0.name.localizedCaseInsensitiveContains(text) }
    }

    var body: some View {
        List {
            // Only offer "Other" when not searching, so search results stay focused.
            if searchText.isEmpty {
                row(name: "", label: "Other / not listed", emoji: "🪴")
            }

            // One section per group, like GROUP BY category. Empty groups are skipped.
            ForEach(PlantCategory.allCases) { category in
                let inCategory = matches.filter { $0.category == category }
                if !inCategory.isEmpty {
                    Section(category.rawValue) {
                        ForEach(inCategory) { species in
                            row(name: species.name, label: species.name, emoji: species.emoji)
                        }
                    }
                }
            }
        }
        .overlay {
            if matches.isEmpty {
                ContentUnavailableView {
                    Label("No matches", systemImage: "magnifyingglass")
                } description: {
                    Text("Try another name, or choose Other / not listed.")
                } actions: {
                    Button("Use Other / not listed") { choose("") }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)   // scrolling the list hides the keyboard
        // A search field pinned above the list. (iOS's built-in .searchable box made
        // you tap a result twice: the first tap only closed the search box.)
        .safeAreaInset(edge: .top) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search plants", text: $searchText)
                    .focused($searchFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(12)
            .background(.regularMaterial, in: Capsule())
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
        .navigationTitle("Plant Type")
        .navigationBarTitleDisplayMode(.inline)
    }

    // One tappable row: emoji, name, and a checkmark on the current choice.
    private func row(name: String, label: String, emoji: String) -> some View {
        Button {
            choose(name)
        } label: {
            HStack(spacing: 12) {
                Text(emoji)
                Text(label)
                Spacer()
                if selection == name {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.leaf)
                        .fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())   // the whole row is tappable, not just the text
        }
        .buttonStyle(.plain)             // normal text color instead of button green
    }

    // Save the choice and go back to the form in one tap, even while searching.
    // (Using "dismiss" here only closed the search box on the first tap.)
    private func choose(_ name: String) {
        selection = name
        isShown = false
    }
}
