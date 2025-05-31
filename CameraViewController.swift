import UIKit
import AVFoundation

// Protocol to send the captured image back to SwiftUI
protocol CameraViewControllerDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
    func cameraAccessDenied()
    func cameraSetupFailed(reason: String) // More specific error reporting
}

class CameraViewController: UIViewController {
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    weak var delegate: CameraViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black // Fallback, previewLayer should cover this
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkCameraPermissionsAndSetupSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure the preview layer always fills the view's bounds after layout changes
        previewLayer?.frame = view.bounds
    }

    private func checkCameraPermissionsAndSetupSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession() // Permission already granted
        case .notDetermined:
            // Request permission. This will suspend the current thread until a response is given.
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                // It's good practice to handle the result on the main thread if it involves UI or session setup.
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        self?.delegate?.cameraAccessDenied()
                    }
                }
            }
        case .denied, .restricted:
            delegate?.cameraAccessDenied() // Permission denied or restricted
        @unknown default:
            delegate?.cameraAccessDenied() // Handle any future unknown cases
        }
    }

    private func setupCaptureSession() {
        guard captureSession == nil || !(captureSession?.isRunning ?? false) else {
            // If session exists but isn't running, try to start it (e.g., after view reappears)
            if let session = captureSession, !session.isRunning {
                 DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
            }
            return
        }

        let newSession = AVCaptureSession()
        newSession.beginConfiguration() // Batch configuration changes

        // Set session preset for photo quality
        if newSession.canSetSessionPreset(.photo) {
            newSession.sessionPreset = .photo
        } else {
            print("Warning: .photo session preset not supported. Using default.")
        }

        // Get video device
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Error: Could not get default back wide-angle camera.")
            delegate?.cameraSetupFailed(reason: "Could not access camera device.")
            newSession.commitConfiguration()
            return
        }

        // Create video input
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if newSession.canAddInput(videoInput) {
                newSession.addInput(videoInput)
            } else {
                print("Error: Could not add video input to session.")
                delegate?.cameraSetupFailed(reason: "Could not add camera input.")
                newSession.commitConfiguration()
                return
            }
        } catch {
            print("Error creating video input: \(error)")
            delegate?.cameraSetupFailed(reason: "Failed to create camera input: \(error.localizedDescription)")
            newSession.commitConfiguration()
            return
        }

        // Create photo output
        let newPhotoOutput = AVCapturePhotoOutput()
        if newSession.canAddOutput(newPhotoOutput) {
            newSession.addOutput(newPhotoOutput)
            self.photoOutput = newPhotoOutput
        } else {
            print("Error: Could not add photo output to session.")
            delegate?.cameraSetupFailed(reason: "Could not add photo output.")
            newSession.commitConfiguration()
            return
        }
        
        newSession.commitConfiguration() // Apply all configuration changes

        // Setup preview layer
        let newPreviewLayer = AVCaptureVideoPreviewLayer(session: newSession)
        newPreviewLayer.videoGravity = .resizeAspectFill
        
        // --- Handle video orientation/rotation for the preview ---
        if let connection = newPreviewLayer.connection {
            if #available(iOS 17.0, *) {
                let desiredAngle: CGFloat = 90        // portrait = 90°, landscape-right = 0°, etc.

                if connection.isVideoRotationAngleSupported(desiredAngle) {
                    connection.videoRotationAngle = desiredAngle
                } else {
                    print("Video rotation angle \(desiredAngle)° isn’t supported.")
                }

            } else {
                // iOS 16 and earlier – fall back to the deprecated orientation API
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }
        
        // UI updates for the layer must be on the main thread
        DispatchQueue.main.async {
            self.previewLayer?.removeFromSuperlayer() // Remove old layer if any
            self.view.layer.insertSublayer(newPreviewLayer, at: 0) // Add new layer at the bottom
            newPreviewLayer.frame = self.view.bounds // Set initial frame
            self.previewLayer = newPreviewLayer
        }
        
        self.captureSession = newSession
        
        // Start the session on a background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak newSession] in
            newSession?.startRunning()
        }
    }

    private func stopSession() {
        if let session = captureSession, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }

    public func takePhoto() {
        guard let activePhotoOutput = self.photoOutput,
              let currentSession = self.captureSession, currentSession.isRunning else {
            print("Error: Photo output not available or session not running.")
            if !(self.captureSession?.isRunning ?? false) {
                print("Attempting to re-initialize session for photo capture.")
                // Re-checking permissions and setup might be too aggressive here
                // Better to ensure session is robustly started in viewDidAppear.
                // For now, just log or inform user.
            }
            return
        }
        
        let photoSettings = AVCapturePhotoSettings()
        // Check for available codecs if you need specific formats like HEIC vs JPEG.
        // For basic JPEG, usually no specific codec type selection is needed if it's default.
        if activePhotoOutput.availablePhotoCodecTypes.contains(.jpeg) {
             photoSettings.photoQualityPrioritization = .balanced // Or .quality, .speed
        }
        // Configure other settings like flashMode if needed:
        // if videoDevice.hasFlash { photoSettings.flashMode = .auto }
        
        activePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            delegate?.cameraSetupFailed(reason: "Photo capture failed: \(error.localizedDescription)")
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            print("Error: Could not get image data from photo.")
            delegate?.cameraSetupFailed(reason: "Could not retrieve image data.")
            return
        }
        
        guard let image = UIImage(data: imageData) else {
            print("Error: Could not convert image data to UIImage.")
            delegate?.cameraSetupFailed(reason: "Could not convert image data.")
            return
        }
        
        delegate?.didCaptureImage(image)
    }
}
