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
    private let openAI: OpenAIService

    init(openAI: OpenAIService = OpenAIService(apiKey: OpenAIKey.apiKey)) {
        self.openAI = openAI
    }

    func generateCard(from uiImage: UIImage) {
        // 1) Enter “Generating image…” state
        phase = .generating(progress: "Generating card art…")

        Task {
            do {
                // 2) Call DALL·E variation endpoint → get new image URL
                let newImageURL = try await openAI.generateImageVariation(from: uiImage)

                // 3) Transition to “Analyzing image…” state
                phase = .generating(progress: "Analyzing image…")

                // 4) Call Vision‐Chat to get title/description/stats
                let analysis = try await openAI.analyzeImageWithVisionChat(uiImage)

                // 5) Convert AnalysisResult to [CardStatItem]
                let stats: [CardStatItem] = analysis.stats.map { stat in
                    if let intVal = Int(stat.value) {
                        return CardStatItem(category: stat.category, value: .int(intVal))
                    } else {
                        return CardStatItem(category: stat.category, value: .string(stat.value))
                    }
                }

                // 6) Build CardContent
                let card = CardContent(
                    id: UUID().uuidString,
                    title: analysis.title,
                    description: analysis.description,
                    localImageName: newImageURL.absoluteString,
                    stats: stats
                )

                // 7) Publish success
                phase = .success(card)

            } catch let openAIError as OpenAIService.OpenAIError {
                // If it’s one of our custom OpenAIError cases, unwrap more detail
                switch openAIError {
                case .httpError(let code, let message):
                    // Show HTTP code + server‐returned message
                    let msg = message ?? "<no message>"
                    phase = .failure("OpenAI HTTP \(code): \(msg)")
                default:
                    // Any other OpenAIError—just display its enum case name
                    phase = .failure("OpenAIError: \(openAIError)")
                }
            } catch {
                // Fallback for any other error types
                phase = .failure("Unexpected error: \(error.localizedDescription)")
            }
        }
    }

    func reset() {
        phase = .idle
    }
}
