//
//  CardGeneratorViewModel.swift
//  YourAppTarget
//
//  Updated to allow dynamic model selection and new card generation flow.
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

    private var openAI: OpenAIService

    // Ensure OpenAIKey.apiKey is properly defined elsewhere and securely managed.
    init(openAI: OpenAIService = OpenAIService(apiKey: OpenAIKey.apiKey, chatModel: "gpt-4o-mini", imageModel: "dall-e-3")) {
        self.openAI = openAI
        self.updateServiceModels()
    }

    /// Call this whenever `selectedTextModel` or `selectedImageModel` changes,
    /// so that future calls use the new model IDs.
    func updateServiceModels() {
        print("[ViewModel] Updating OpenAI Service with Chat: \(selectedTextModel), Image: \(selectedImageModel)")
        openAI = OpenAIService(
            apiKey: OpenAIKey.apiKey, // Ensure this is correctly sourced
            chatModel: selectedTextModel,
            imageModel: selectedImageModel
        )
    }

    /// Generate card by:
    /// 1) Analyzing the input image with Vision-Chat (using `selectedTextModel`) to get structured data including a `detailedSubjectDescription`.
    /// 2) Generating a new card image using DALL·E (via `generateImageFromText` with `selectedImageModel`) based on the `detailedSubjectDescription` and a style template.
    /// 3) Assembling the `CardContent`.
    func generateCard(from uiImage: UIImage) {
        Task {
            do {
                // 1. Analyze Image with Vision
                phase = .generating(progress: "Analyzing image with \(selectedTextModel)...")
                
                let visionPrompt = OpenAIPrompts.shared.defaultTextPrompt
                let analysisResult = try await openAI.analyzeImageWithVisionChat(uiImage, prompt: visionPrompt)

                // 2. Prepare for Image Generation
                let imageStyleTemplate = OpenAIPrompts.shared.defaultImagePrompt
                
                // Ensure detailedSubjectDescription from AnalysisResult is not empty
                // (Assuming Models.swift has `detailedSubjectDescription` in AnalysisResult)
                guard !analysisResult.detailedSubjectDescription.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
                    print("[ViewModel] Error: detailedSubjectDescription from analysis is empty.")
                    // You might want a more specific error for your OpenAIError enum
                    throw OpenAIService.OpenAIError.unexpectedResponseFormat
                }
                
                let finalImageGenPrompt = imageStyleTemplate.replacingOccurrences(
                    of: "[SUBJECT_DESCRIPTION]",
                    with: analysisResult.detailedSubjectDescription
                )

                print("[ViewModel] Final image generation prompt: \(finalImageGenPrompt)")
                phase = .generating(progress: "Generating card art with \(selectedImageModel)...")

                // 3. Generate Image from Text
                let newImageURL = try await openAI.generateImageFromText(
                    prompt: finalImageGenPrompt,
                    size: 1024,
                    quality: "standard",
                    style: "vivid"
                )

                // 4. Convert AnalysisResult.stats → [CardStatItem]
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

                // 5. Build CardContent
                // 🔽 FIXED LINE: Use 'localImageName' if that's what CardContent expects
                let card = CardContent(
                    id: UUID().uuidString,
                    title: analysisResult.title,
                    description: analysisResult.description,
                    localImageName: newImageURL.absoluteString, // Changed back to localImageName
                    stats: stats
                )

                // 6. Publish success
                phase = .success(card)

            } catch let openAIError as OpenAIService.OpenAIError {
                let errorMessage: String
                switch openAIError {
                case .httpError(let code, let message):
                    errorMessage = "OpenAI HTTP \(code): \(message ?? "Unknown error")"
                case .jsonDecodingError(_, let rawJSON): // Assuming this case exists in your OpenAIError
                    errorMessage = "Failed to decode JSON. Raw: \(rawJSON.prefix(200))..."
                case .visionChatDidNotReturnContent:
                    errorMessage = "Vision chat did not return content. Check prompt and model."
                case .unexpectedResponseFormat:
                    errorMessage = "Unexpected response format from AI."
                // Add other specific OpenAIError cases if you have them
                default:
                    errorMessage = "OpenAI Error: \(openAIError)" // Fallback for other OpenAIError cases
                }
                print("[ViewModel] Error: \(errorMessage)")
                phase = .failure(errorMessage)
            } catch {
                print("[ViewModel] Unexpected error: \(error.localizedDescription)")
                phase = .failure("Unexpected error: \(error.localizedDescription)")
            }
        }
    }

    func reset() {
        phase = .idle
    }
}
