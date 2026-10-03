import SwiftUI
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
        // the same one the Photos app uses; Gaia itself never sends the photo anywhere.
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
