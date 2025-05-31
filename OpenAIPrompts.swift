import Foundation

/// Which “bucket” the prompt belongs to.
enum OpenAIPromptDomain: CaseIterable { case image, text }

/// A single reusable prompt template.
struct OpenAIPrompt: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var body: String          // The raw text sent to OpenAI
}

/// Singleton store. Add / reorder prompts at runtime if you expose UI for it.
final class OpenAIPrompts {
    static let shared = OpenAIPrompts(); private init() {}

    // MARK: - Presets
    private(set) var imagePrompts: [OpenAIPrompt] = [
        .init(
            title: "Card Art • V1",
            body: """
                  Create a vibrant, high-impact illustration suitable for a collectible
                  stats card. Keep the background minimal; emphasise the subject with
                  bold lighting, clean vector-style edges and rich colour contrast.
                  """
        )
    ]

    private(set) var textPrompts: [OpenAIPrompt] = [
        .init(
            title: "Analyse Product • V1",
            body: """
                  You are a product analyst. From the provided image identify the item,
                  describe it in 2–3 sentences, then infer exactly four compelling stats
                  (quantitative or qualitative). Return **ONLY** valid minified JSON:

                  {
                    "title": <string>,
                    "description": <string>,
                    "stats": [
                      { "category": <string>, "value": <string> },
                      …
                    ]
                  }
                  """
        )
    ]

    // MARK: - Convenience
    var defaultImagePrompt: String { imagePrompts.first!.body }
    var defaultTextPrompt:  String { textPrompts .first!.body }

    /// Moves a chosen prompt to the front so `default*Prompt` picks it up.
    func setActivePrompt(for domain: OpenAIPromptDomain, id: OpenAIPrompt.ID) {
        switch domain {
        case .image:
            guard let i = imagePrompts.firstIndex(where: { $0.id == id }) else { return }
            imagePrompts.insert(imagePrompts.remove(at: i), at: 0)

        case .text:
            guard let i = textPrompts.firstIndex(where: { $0.id == id }) else { return }
            textPrompts.insert(textPrompts.remove(at: i), at: 0)
        }
    }
}
