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
    func generateCard(from uiImage: UIImage, completion: @escaping (Result<CardContent, Error>) -> Void) {
        guard let currentOpenAIService = openAI else {
            print("[ViewModel] Cannot generate card: OpenAIService is not initialized.")
            let errorMsg = "OpenAI Service not available. Please check setup or restart the app."
            // Ensure the completion handler is called asynchronously to allow UI to update first
            DispatchQueue.main.async {
                if !self.phaseIsServiceInitError() { // If not already in an init error, set one.
                     self.phase = .failure(errorMsg)
                }
                completion(.failure(GeneratorError(message: errorMsg)))
            }
            return
        }

        Task {
            do {
                phase = .generating(progress: "Generating card data with \(selectedTextModel)...")
                
                // Step 1: Get all card data (title, stats JSON, art prompt) from the new service method
                let (title, statsJSON, artPrompt, analysisData) = try await currentOpenAIService.generateCardDataFromImage(image: uiImage)
                print("[ViewModel] Received card data. Title: \(title), Art Prompt: \(artPrompt.prefix(100))...")

                // Step 2: Generate image using the artPrompt
                print("[ViewModel] Generating card art with \(selectedImageModel). Prompt: \(artPrompt.prefix(200))...")
                phase = .generating(progress: "Generating card art with \(selectedImageModel)...")

                let newImageURL = try await currentOpenAIService.generateImageFromText(
                    prompt: artPrompt, // Use the generated artPrompt directly
                    size: 1024,
                    quality: "standard", // Or user-selectable options
                    style: "vivid"       // Or user-selectable options
                )
                print("[ViewModel] Card art generated: \(newImageURL.absoluteString)")

                // Step 3: Parse statsJSON and convert to [CardStatItem]
                let stats = try parseAndConvertStats(from: statsJSON)
                print("[ViewModel] Stats parsed and converted.")

                // Step 4: Assemble CardContent
                // For description, using visualTraits. Fallback to subject if empty.
                let descriptionText = analysisData.visualTraits.isEmpty ? analysisData.subject : analysisData.visualTraits

                // Generate displayId
                let currentTotalCards = UserDefaults.standard.integer(forKey: "totalSnapFactsCardsMade")
                let newDisplayId = currentTotalCards + 1
                UserDefaults.standard.set(newDisplayId, forKey: "totalSnapFactsCardsMade")
                
                let card = CardContent(
                    id: UUID().uuidString, // Keep unique ID generation
                    displayId: newDisplayId,
                    title: title,
                    description: descriptionText, 
                    detailedSubjectDescription: artPrompt, // Store the art prompt here
                    localImageName: newImageURL.absoluteString,
                    stats: stats
                )
                print("[ViewModel] CardContent assembled. Title: \(card.title)")

                phase = .success(card)
                completion(.success(card))

            } catch let openAIError as OpenAIService.OpenAIError {
                let errorMessage = errorDescription(for: openAIError)
                print("[ViewModel] OpenAI Error during card generation: \(errorMessage)")
                phase = .failure("OpenAI Error: \(errorMessage)")
                completion(.failure(GeneratorError(message: "OpenAI Error: \(errorMessage)")))
            } catch {
                let errorMessage = error.localizedDescription
                print("[ViewModel] General Error during card generation: \(errorMessage)")
                phase = .failure("Error: \(errorMessage)")
                completion(.failure(GeneratorError(message: "Error: \(errorMessage)")))
            }
        }
    }

    private func parseAndConvertStats(from statsJSON: String) throws -> [CardStatItem] {
        guard let jsonData = statsJSON.data(using: .utf8) else {
            print("[ViewModel] Error: Could not convert statsJSON string to Data.")
            // Consider a more specific error type or log details
            throw OpenAIService.OpenAIError.unexpectedResponseFormat 
        }
        
        // Restored do-catch block for parsing stats
        do {
            let decodedStatsContainer = try JSONDecoder().decode(StatsContainer.self, from: jsonData)
            
            return decodedStatsContainer.stats.map { decodedStat -> CardStatItem in
                let value: StatValue
                // The value from DecodedStatItem is always a String.
                // Attempt to parse as Int; if fails, keep as String.
                if let intVal = Int(decodedStat.value) {
                    value = .int(intVal)
                } else {
                    // You could add more sophisticated parsing here if needed (e.g., for Doubles)
                    value = .string(decodedStat.value)
                }
                return CardStatItem(category: decodedStat.category, value: value)
            }
        } catch {
            print("[ViewModel] Error decoding statsJSON: \(error.localizedDescription). JSON received: \(statsJSON)")
            // Propagate the error; could be a decoding error or other JSON issue
            throw error 
        }
    }

    // Custom error for the generator - correctly positioned at class level
    struct GeneratorError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
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
