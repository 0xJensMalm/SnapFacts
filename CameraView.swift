import SwiftUI
import UIKit     // for UIImage

// MARK: - Shared button styling
struct CameraButtonModifier: ViewModifier {
    let backgroundColor: Color
    let textColor: Color
    let outlineColor: Color

    func body(content: Content) -> some View {
        content
            .font(UIConfigLayout.actionButtonFont)
            .foregroundColor(textColor)
            .padding(UIConfigLayout.actionButtonPadding)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(UIConfigLayout.actionButtonCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: UIConfigLayout.actionButtonCornerRadius)
                    .stroke(outlineColor, lineWidth: UIConfigLayout.actionButtonOutlineWidth)
            )
    }
}

// MARK: - Main view
struct CameraView: View {

    // Camera capture state
    enum CameraCaptureState { case capturing, imagePreview, permissionDenied }

    // UI / theme
    @StateObject private var themeManager = ThemeManager(initialTheme: .cameraTheme)
    @State private var currentCaptureState: CameraCaptureState = .capturing

    // Captured image
    @State private var capturedUIImage: UIImage?
    private var imageToDisplay: Image? {
        capturedUIImage.map { Image(uiImage: $0) }
    }

    // Triggers
    @State private var triggerCapture  = false
    @State private var showPermissionAlert = false

    // OpenAI generator
    @StateObject private var generator = CardGeneratorViewModel()

    // MARK: - Helpers
    private func handleTakePictureRequest() { triggerCapture = true }

    private func retakePicture() {
        capturedUIImage = nil
        currentCaptureState = .capturing
    }

    private func confirmPicture() {
        guard let img = capturedUIImage else { return }
        generator.generateCard(from: img)
    }

    private func handleCameraAccessDenied() {
        currentCaptureState = .permissionDenied
        showPermissionAlert = true
    }

    // MARK: - View
    var body: some View {
        NavigationStack {
            ZStack {

                // ───────── Camera / Preview background ─────────
                Group {
                    switch currentCaptureState {
                    case .capturing:
                        CameraRepresentableView(
                            capturedUIImage: $capturedUIImage,
                            takePictureTrigger: $triggerCapture,
                            onAccessDenied: handleCameraAccessDenied
                        )

                    case .imagePreview:
                        if let displayImg = imageToDisplay {
                            displayImg
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black)
                        }

                    case .permissionDenied:
                        Color.black.overlay(
                            VStack {
                                Image(systemName: "camera.slash.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                Text("Camera access was denied.")
                                    .foregroundColor(.white)
                                    .padding()
                                Text("Please enable camera access in Settings.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .onChange(of: capturedUIImage) { _, newImg in
                    if newImg != nil { currentCaptureState = .imagePreview }
                }

                // ───────── HUD (header + bottom buttons) ─────────
                if currentCaptureState != .permissionDenied {
                    VStack(spacing: 0) {

                        // Header (Logo Banner)
                        ZStack {
                            Color(red: 0.99, green: 0.94, blue: 0.84) // Tan background

                            VStack {
                                Spacer()
                                Image("snapFacts")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 120) // Ensure logo shows
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.2) // 30% of screen height

                        Spacer()
                        // Bottom controls
                        VStack(spacing: UIConfigLayout.controlsContainerSpacing) {
                            if currentCaptureState == .imagePreview {
                                Button("New Picture", action: retakePicture)
                                    .modifier(CameraButtonModifier(
                                        backgroundColor: Color.red, // Red background
                                        textColor: Color(red: 0.99, green: 0.94, blue: 0.84), // Tan text
                                        outlineColor: Color.black // Optional: black border
                                    ))
                            }

                            Button(
                                currentCaptureState == .capturing ? "Analyze" : "Confirm",
                                action: {
                                    currentCaptureState == .capturing
                                    ? handleTakePictureRequest()
                                    : confirmPicture()
                                })
                                .modifier(CameraButtonModifier(
                                    backgroundColor: Color.red, // Red background
                                    textColor: Color(red: 0.99, green: 0.94, blue: 0.84), // Tan text
                                    outlineColor: Color.black // Optional: black border
                                ))
                        }
                        .padding(UIConfigLayout.controlsContainerPadding)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.99, green: 0.94, blue: 0.84)) // Tan fill
                        .ignoresSafeArea(edges: .bottom)
                        .padding(.horizontal, UIConfigLayout.contentHorizontalPadding)
                        .padding(.bottom, 10)
                    }
                }

                // ───────── Generator overlay (progress / error) ─────────
                switch generator.phase {
                case .generating(let status):
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text(status).foregroundColor(.white)
                    }

                case .failure(let message):
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.octagon")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Generation failed")
                            .bold()
                            .foregroundColor(.white)
                        Text(message)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                        Button("Dismiss") { generator.reset() }
                            .padding(.top, 4)
                    }

                default:
                    EmptyView()
                }
            }
            .environmentObject(themeManager)
            .alert("Camera Access Denied", isPresented: $showPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("To use the camera, please enable access in your iPhone's Settings app.")
            }
            // ───────── Navigation to generated card ─────────
            .navigationDestination(isPresented: Binding(
                get: { if case .success = generator.phase { true } else { false } },
                set: { _ in }
            )) {
                if case .success(let card) = generator.phase {
                    CardView(cardContent: card)
                        .toolbar { Button("Done") { generator.reset() } }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview { CameraView() }
