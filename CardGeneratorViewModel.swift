//
//  CardGeneratorViewModel.swift
//  YourAppTarget
//
//  Updated to allow dynamic model selection, new card generation flow,
//  and OpenAIService internal API key management.
//

import Foundation
import UIKit

@MainActor
final class CardGeneratorViewModel: ObservableObject {
    enum Phase {
        case idle
        case generating(progress: String)
        case success(CardContent)
        case failure(String)
        case serviceInitializationError(String) // New phase for init errors
    }

    @Published private(set) var phase: Phase = .idle

    /// Currently selected chat/vision model (e.g. "gpt-4o", "gpt-4o-mini")
    @Published var selectedTextModel: String = "gpt-4o-mini" {
        didSet {
            if oldValue != selectedTextModel { updateServiceModels() }
        }
    }

    /// Currently selected image model (e.g. "dall-e-3", "dall-e-2")
    @Published var selectedImageModel: String = "dall-e-3" {
        didSet {
            if oldValue != selectedImageModel { updateServiceModels() }
        }
    }

    // openAI is now an optional, as its initialization can fail (e.g., API key not found)
    private var openAI: OpenAIService?

    init() {
        // Attempt to initialize OpenAIService.
        // If this fails (e.g., API key issue), set an error phase.
        // The UI should then reflect that the service couldn't be started.
        do {
            // Pass initial model selections from @Published properties
            self.openAI = try OpenAIService(
                chatModel: self.selectedTextModel,
                imageModel: self.selectedImageModel
            )
            print("[ViewModel] OpenAIService initialized successfully.")
        } catch let error as OpenAIService.OpenAIError {
            let errorMessage = "Failed to initialize OpenAI Service: \(errorDescription(for: error)). Please check API key setup."
            print("[ViewModel] CRITICAL ERROR: \(errorMessage)")
            self.phase = .serviceInitializationError(errorMessage)
            self.openAI = nil // Ensure it's nil if init failed
        } catch {
            let errorMessage = "An unexpected error occurred during OpenAI Service initialization: \(error.localizedDescription)"
            print("[ViewModel] CRITICAL ERROR: \(errorMessage)")
            self.phase = .serviceInitializationError(errorMessage)
            self.openAI = nil
        }
    }

    /// Call this whenever `selectedTextModel` or `selectedImageModel` changes,
    /// so that future calls use the new model IDs.
    func updateServiceModels() {
        // Ensure we don't try to update if the initial setup failed and openAI is nil
        guard self.openAI != nil || self.phaseIsServiceInitError() else {
            print("[ViewModel] Skipping model update as OpenAIService is not initialized.")
            // If it failed before, it will likely fail again.
            // You might want to re-attempt initialization or keep the error state.
            // For simplicity, we'll just log and return if initial setup failed.
            if case .serviceInitializationError(let existingError) = self.phase {
                print("[ViewModel] Service previously failed to initialize: \(existingError)")
            } else {
                // This case should ideally not be hit if openAI is nil without a serviceInitError phase,
                // but as a fallback, try to re-initialize.
                do {
                    self.openAI = try OpenAIService(
                        chatModel: selectedTextModel,
                        imageModel: selectedImageModel
                    )
                    print("[ViewModel] OpenAIService re-initialized successfully during model update.")
                    if case .serviceInitializationError = self.phase { self.phase = .idle } // Clear previous init error
                } catch {
                    let errorMessage = "Failed to re-initialize OpenAI Service during model update: \(error.localizedDescription)"
                    print("[ViewModel] CRITICAL ERROR: \(errorMessage)")
                    self.phase = .serviceInitializationError(errorMessage)
                    self.openAI = nil
                }
            }
            return
        }
        
        // If openAI was initialized, try to create a new instance with updated models.
        print("[ViewModel] Updating OpenAI Service with Chat: \(selectedTextModel), Image: \(selectedImageModel)")
        do {
            self.openAI = try OpenAIService(
                chatModel: selectedTextModel,
                imageModel: selectedImageModel
            )
            print("[ViewModel] OpenAIService updated successfully.")
            // If we were in an error state due to models but init now works, reset phase
             if case .serviceInitializationError = self.phase { self.phase = .idle }
        } catch let error as OpenAIService.OpenAIError {
            let errorMessage = "Failed to update OpenAI Service: \(errorDescription(for: error))."
            print("[ViewModel] ERROR: \(errorMessage)")
            self.phase = .serviceInitializationError(errorMessage) // Can use the same error phase
            // Keep the old openAI instance or set to nil?
            // Setting to nil indicates service is unusable.
            self.openAI = nil
        } catch {
            let errorMessage = "An unexpected error occurred while updating OpenAI Service: \(error.localizedDescription)"
            print("[ViewModel] ERROR: \(errorMessage)")
            self.phase = .serviceInitializationError(errorMessage)
            self.openAI = nil
        }
    }
    
    private func phaseIsServiceInitError() -> Bool {
        if case .serviceInitializationError = self.phase { return true }
        return false
    }

    /// Generate card by:
    /// 1) Analyzing the input image with Vision-Chat.
    /// 2) Generating a new card image using DALL·E.
    /// 3) Assembling the `CardContent`.
    func generateCard(from uiImage: UIImage) {
        guard let currentOpenAIService = openAI else {
            print("[ViewModel] Cannot generate card: OpenAIService is not initialized.")
            if !phaseIsServiceInitError() { // If not already in an init error, set one.
                 self.phase = .failure("OpenAI Service not available. Please check setup or restart the app.")
            }
            return
        }

        Task {
            do {
                phase = .generating(progress: "Analyzing image with \(selectedTextModel)...")
                
                let visionPrompt = OpenAIPrompts.shared.defaultTextPrompt
                let analysisResult = try await currentOpenAIService.analyzeImageWithVisionChat(uiImage, prompt: visionPrompt)

                let imageStyleTemplate = OpenAIPrompts.shared.defaultImagePrompt
                
                guard !analysisResult.detailedSubjectDescription.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
                    print("[ViewModel] Error: detailedSubjectDescription from analysis is empty.")
                    throw OpenAIService.OpenAIError.unexpectedResponseFormat
                }
                
                let finalImageGenPrompt = imageStyleTemplate.replacingOccurrences(
                    of: "[SUBJECT_DESCRIPTION]",
                    with: analysisResult.detailedSubjectDescription
                )

                print("[ViewModel] Final image generation prompt: \(finalImageGenPrompt.prefix(200))...") // Log prefix
                phase = .generating(progress: "Generating card art with \(selectedImageModel)...")

                let newImageURL = try await currentOpenAIService.generateImageFromText(
                    prompt: finalImageGenPrompt,
                    size: 1024,
                    quality: "standard",
                    style: "vivid"
                )

                let stats: [CardStatItem] = analysisResult.stats.map { stat -> CardStatItem in
                    let value: StatValue
                    if let intVal = Int(stat.value) {
                        value = .int(intVal)
                    } else {
                        if let doubleVal = Double(stat.value) {
                             if floor(doubleVal) == doubleVal && !stat.value.contains(".") {
                                 value = .int(Int(doubleVal))
                             } else {
                                 value = .string(stat.value)
                             }
                        } else {
                             value = .string(stat.value)
                        }
                    }
                    return CardStatItem(category: stat.category, value: value)
                }

                let card = CardContent(
                    id: UUID().uuidString,
                    title: analysisResult.title,
                    description: analysisResult.description,
                    localImageName: newImageURL.absoluteString,
                    stats: stats
                )

                phase = .success(card)

            } catch let openAIError as OpenAIService.OpenAIError {
                let errorMessage = errorDescription(for: openAIError)
                print("[ViewModel] Error during card generation: \(errorMessage)")
                phase = .failure("OpenAI Error: \(errorMessage)")
            } catch {
                let errorMessage = error.localizedDescription
                print("[ViewModel] Unexpected error during card generation: \(errorMessage)")
                phase = .failure("Unexpected error: \(errorMessage)")
            }
        }
    }

    func reset() {
        // If service init failed, reset might not put it back to idle if the underlying issue isn't fixed.
        // However, for other errors, idle is fine.
        if case .serviceInitializationError(let msg) = phase {
            // Keep the error state, or try to re-init? For now, keep.
            print("[ViewModel] Reset called, but service initialization previously failed: \(msg)")
            // Optionally, you could try to re-initialize here:
            // init() // This would call the initializer again.
        } else {
            phase = .idle
        }
    }

    // Helper to get user-friendly descriptions for OpenAIError
    private func errorDescription(for error: OpenAIService.OpenAIError) -> String {
        switch error {
        case .apiKeyNotFound:
            return "API Key not found or invalid. Please check your app configuration."
        case .httpError(let code, let message):
            return "Network request failed (HTTP \(code)): \(message ?? "No details")"
        case .jsonDecodingError(_, let rawJSON):
            return "Failed to understand response from server. Raw data: \(rawJSON.prefix(100))..."
        case .visionChatDidNotReturnContent:
            return "Image analysis did not return expected content."
        case .unexpectedResponseFormat:
            return "Received an unexpected response format from the server."
        case .noImageReturned:
            return "No image was returned by the generation process."
        default:
            return "\(error)" // Fallback for other specific errors like image encoding
        }
    }
}
