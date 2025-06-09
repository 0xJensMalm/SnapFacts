//
//  CameraView.swift
//  YourAppTarget
//
//  Main camera screen with “Options” button to choose models.
//

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
    @StateObject private var themeManager = ThemeManager()
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

    // **NEW**: whether to show the sheet for model options
    @State private var showModelOptions = false

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
                                .background(themeManager.currentTheme.cardBackground)
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

                        // Header (Logo Banner) + “Options” button
                        ZStack {
                            themeManager.currentTheme.bottomContainerBackground // Themed background

                            HStack {
                                Spacer()

                                VStack {
                                    Spacer()
                                    Image("snapFacts")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 120) // Ensure logo shows
                                    Spacer()
                                }

                                Spacer()

                                // **Options** (gear) button
                                Button {
                                    showModelOptions = true
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title2)
                                        .foregroundColor(themeManager.currentTheme.titleText)
                                        .padding(.trailing, 16)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.2)

                        Spacer()

                        // Bottom controls
                        VStack(spacing: UIConfigLayout.controlsContainerSpacing) {
                            if currentCaptureState == .imagePreview {
                                Button("New Picture", action: retakePicture)
                                    .modifier(CameraButtonModifier(
                                        backgroundColor: Color.red, // Destructive action, keep red
                                        textColor: themeManager.currentTheme.tagText, // Themed text
                                        outlineColor: themeManager.currentTheme.innerFrameLine // Themed outline
                                    ))
                            }

                            Button(
                                currentCaptureState == .capturing ? "Analyze" : "Confirm",
                                action: {
                                    if currentCaptureState == .capturing {
                                        handleTakePictureRequest()
                                    } else {
                                        confirmPicture()
                                    }
                                })
                                .modifier(CameraButtonModifier(
                                    backgroundColor: themeManager.currentTheme.tagBackground, // Themed background
                                    textColor: themeManager.currentTheme.tagText, // Themed text
                                    outlineColor: themeManager.currentTheme.innerFrameLine // Themed outline
                                ))
                        }
                        .padding(UIConfigLayout.controlsContainerPadding)
                        .frame(maxWidth: .infinity)
                        .background(themeManager.currentTheme.bottomContainerBackground) // Themed fill
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
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("To use the camera, please enable access in your iPhone's Settings app.")
            }
            // ───────── Navigation to generated card ─────────
            .navigationDestination(isPresented: Binding(
                get: { if case .success = generator.phase { return true } else { return false } },
                set: { _ in }
            )) {
                if case .success(let card) = generator.phase {
                    CardView(cardContent: card, isFromSnapDex: false)
                        .toolbar { Button("Done") { generator.reset() } }
                }
            }
            // ───────── Model Options Sheet ─────────
            .sheet(isPresented: $showModelOptions) {
                VStack(spacing: 24) {
                    Text("Select Models")
                        .font(.headline)
                        .padding(.top, 16)
                    
                    // MARK: – Text/Vision Model Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Text/Vision Model:")
                            .font(.subheadline)
                            .bold()
                        Picker("Text Model", selection: $generator.selectedTextModel) {
                            Text("GPT-4.1").tag("gpt-4.1")                    //
                            Text("GPT-4.1 Mini").tag("gpt-4.1-mini")
                            Text("GPT-4.O Mini").tag("gpt-4o-mini")
                            Text("GPT-4O").tag("gpt-4o")
                            Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    
                    // MARK: – Image Model Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Image Model:")
                            .font(.subheadline)
                            .bold()
                        Picker("Image Model", selection: $generator.selectedImageModel) {
                            Text("DALL·E 3").tag("dall-e-3")             //
                            Text("DALL·E 2").tag("dall-e-2")
                            Text("GPT Image 1").tag("gpt-image-1")       //
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    Button("Done") {
                        showModelOptions = false
                        // Recreate the service with the new model IDs
                        generator.updateServiceModels()
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CameraView()
}
