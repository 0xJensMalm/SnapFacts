import SwiftUI
import UIKit

struct CameraRepresentableView: UIViewControllerRepresentable {
    // Binding to pass the captured image back to the SwiftUI view
    @Binding var capturedUIImage: UIImage?
    // Binding to trigger photo capture from SwiftUI
    @Binding var takePictureTrigger: Bool
    // Callback for permission issues
    var onAccessDenied: () -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator // Set the coordinator as the delegate
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // If the trigger is set to true, tell the controller to take a photo
        if takePictureTrigger {
            uiViewController.takePhoto()
            // Reset the trigger immediately on the main thread
            DispatchQueue.main.async {
                self.takePictureTrigger = false
            }
        }
    }

    // Creates the coordinator instance
    func makeCoordinator() -> Coordinator { // Ensure this returns your coordinator class name
        Coordinator(self) // Use "Coordinator" if your class is named "Coordinator"
    }

    // Coordinator class to handle delegate callbacks from CameraViewController
    // RENAME "HerCoordinator" to "Coordinator" to match the makeCoordinator() return type,
    // OR change makeCoordinator() to return HerCoordinator. Let's assume renaming to "Coordinator":
    class Coordinator: NSObject, CameraViewControllerDelegate { // Renamed to Coordinator
        var parent: CameraRepresentableView

        init(_ parent: CameraRepresentableView) {
            self.parent = parent
        }

        func didCaptureImage(_ image: UIImage) {
            parent.capturedUIImage = image
        }

        func cameraAccessDenied() {
            parent.onAccessDenied()
        }

        // ADD THIS MISSING METHOD:
        func cameraSetupFailed(reason: String) {
            print("CameraRepresentableView.Coordinator: Camera setup failed - \(reason)")
            // You might want to propagate this error further, e.g., via another callback to CameraView
            // For now, just printing. You could also call parent.onAccessDenied() or a new error callback.
            parent.onAccessDenied() // Reusing onAccessDenied for simplicity here, or add a specific error handler
        }
    }
}
