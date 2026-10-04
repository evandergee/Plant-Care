import SwiftUI
import SwiftData
import UIKit
import VisionKit

// STEP 16: Your own plant photos.
// A photo can be taken with the camera or chosen from the library. It's shrunk,
// saved with the plant, shown in the list instead of the emoji, and can be opened
// full screen, where iOS can identify the plant (Apple's "Visual Look Up").

// Phone photos can be 5 MB or more. This shrinks one so its longest side is
// 1200 pixels, which still looks sharp full screen but is about 20 times smaller.
func shrunkPhoto(_ image: UIImage, maxSide: CGFloat = 1200) -> Data? {
    let scale = min(1, maxSide / max(image.size.width, image.size.height))
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1   // real pixels, not screen points
    let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
        image.draw(in: CGRect(origin: .zero, size: size))
    }
    return resized.jpegData(compressionQuality: 0.8)
}

// The camera screen. SwiftUI has no camera view of its own, so this wraps
// UIKit's camera (UIImagePickerController) so it can be used from SwiftUI.
struct CameraPicker: UIViewControllerRepresentable {
    var onPhoto: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // UIKit reports "photo taken" or "cancelled" to this helper object.
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onPhoto(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// A photo with Visual Look Up turned on. When iOS recognizes a plant, it puts a small
// leaf icon on the photo; tapping it shows what the plant is. This also comes from UIKit.
struct LookUpImageView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        // Let SwiftUI size the photo to the screen instead of the photo's full pixel size.
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let interaction = ImageAnalysisInteraction()
        interaction.preferredInteractionTypes = .visualLookUp
        view.addInteraction(interaction)

        // Ask iOS to look for things it can identify. This is Apple's built-in feature,
        // the same one the Photos app uses; DeTerra itself never sends the photo anywhere.
        Task {
            guard ImageAnalyzer.isSupported else { return }   // false in the simulator
            let configuration = ImageAnalyzer.Configuration([.visualLookUp])
            interaction.analysis = try? await ImageAnalyzer().analyze(image, configuration: configuration)
        }
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {}
}

// Full-screen photo viewer, opened by tapping the photo on the plant form.
struct PhotoViewer: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LookUpImageView(image: image)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .safeAreaInset(edge: .bottom) {
                    Text(ImageAnalyzer.isSupported
                         ? "If your iPhone recognizes the plant, a small leaf icon appears on the photo. Tap it to see what it is."
                         : "Plant identification works on an iPhone, not in the simulator.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
                .toolbarBackground(.black, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// STEP 17: Growth timeline.
// Every photo is kept with its date instead of replacing the last one, so you can
// see how a plant has grown. Like the watering history, it's a second table:
// one plant has many photos (a plant_photos table with a plant_id foreign key).

@Model
final class PlantPhoto {
    @Attribute(.externalStorage) var data: Data   // the JPEG, stored as a file next to the database
    var date: Date
    var plant: Plant?

    init(data: Data, date: Date = Date()) {
        self.data = data
        self.date = date
    }
}

extension Plant {
    var photosNewestFirst: [PlantPhoto] { photos.sorted { $0.date > $1.date } }
    var latestPhoto: PlantPhoto? { photos.max { $0.date < $1.date } }
    var firstPhoto: PlantPhoto? { photos.min { $0.date < $1.date } }

    func addPhoto(_ data: Data, on date: Date = Date()) {
        photos.append(PlantPhoto(data: data, date: date))
    }

    // Plants saved before the timeline existed had a single photo in photoData.
    // Move it into the timeline once, so nothing is lost.
    func moveOldPhotoIntoTimeline() {
        if let old = photoData {
            addPhoto(old, on: dateAdded)
            photoData = nil
        }
    }
}

// "4 months of growth", "12 days of growth".
func growthText(from start: Date, to end: Date) -> String {
    let parts = Calendar.current.dateComponents([.month, .day], from: start, to: end)
    let months = parts.month ?? 0
    let days = parts.day ?? 0
    if months > 0 { return "\(months) month\(months == 1 ? "" : "s") of growth" }
    if days > 0 { return "\(days) day\(days == 1 ? "" : "s") of growth" }
    return "Taken the same day"
}

// The growth timeline screen: "Then and now" side by side, then every photo.
struct GrowthTimelineView: View {
    let plant: Plant
    @Environment(\.modelContext) private var context
    @State private var viewing: PlantPhoto?   // the photo open full screen

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        List {
            if let first = plant.firstPhoto, let latest = plant.latestPhoto, first !== latest {
                Section {
                    HStack(spacing: 10) {
                        thenNowPhoto(first, label: "Then")
                        thenNowPhoto(latest, label: "Now")
                    }
                } header: {
                    Text("Then and Now")
                } footer: {
                    Text(growthText(from: first.date, to: latest.date))
                }
            }

            Section {
                if plant.photos.isEmpty {
                    Text("No photos yet. Add one from the plant form.")
                        .foregroundStyle(.secondary)
                }
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(plant.photosNewestFirst) { photo in
                        VStack(spacing: 4) {
                            photoTile(photo)
                                .frame(height: 100)
                                .onTapGesture { viewing = photo }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(photo)
                                    } label: {
                                        Label("Delete photo", systemImage: "trash")
                                    }
                                }
                            Text(photo.date, format: .dateTime.month(.abbreviated).day().year())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("All Photos")
            } footer: {
                if plant.photos.count == 1 {
                    Text("Add another photo later to compare. Touch and hold a photo to delete it.")
                } else if plant.photos.count > 1 {
                    Text("Tap a photo to view it. Touch and hold a photo to delete it.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(GardenBackground())
        .navigationTitle("Growth Timeline")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $viewing) { photo in
            if let image = UIImage(data: photo.data) {
                PhotoViewer(image: image)
            }
        }
    }

    private func thenNowPhoto(_ photo: PlantPhoto, label: String) -> some View {
        VStack(spacing: 4) {
            photoTile(photo)
                .frame(height: 150)
                .onTapGesture { viewing = photo }
            Text(label).font(.caption.weight(.semibold))
            Text(photo.date, format: .dateTime.month(.abbreviated).day().year())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func photoTile(_ photo: PlantPhoto) -> some View {
        Color.clear
            .overlay {
                if let image = UIImage(data: photo.data) {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
    }

    // DELETE FROM plant_photos WHERE ...
    private func delete(_ photo: PlantPhoto) {
        plant.photos.removeAll { $0 == photo }
        context.delete(photo)
    }
}
