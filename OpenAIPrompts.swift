// OpenAIPrompts.swift

import Foundation

/// Which “bucket” the prompt belongs to.
enum OpenAIPromptDomain: CaseIterable { case image, text }

/// A single reusable prompt template.
struct OpenAIPrompt: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var body: String      // The raw text sent to OpenAI, potentially a template
}

/// Singleton store. Add / reorder prompts at runtime if you expose UI for it.
final class OpenAIPrompts {
    static let shared = OpenAIPrompts(); private init() {}

    // MARK: - Presets
    private(set) var imagePrompts: [OpenAIPrompt] = [
        .init(
            title: "Card Art • V3", // Updated version
            body: """
            A collectible card art style illustration of [SUBJECT_DESCRIPTION].
            The subject should be the clear focus.
            Key style features to emphasize:
            • Bold lines, clean edges, and vibrant colors.
            • A minimal or stylized background that makes the [SUBJECT_DESCRIPTION] stand out.
            • Rendered in a flat shading, stylized shape, with a clear outline, suitable for a unique collectible card.
            """
        ),
        // You can add more image style prompts here
        .init(
            title: "Photorealistic Card Art",
            body: """
            A photorealistic image of [SUBJECT_DESCRIPTION], suitable for a collectible card.
            Focus on high detail and realistic textures. The background should be simple or a subtle gradient.
            """
        )
    ]

    private(set) var textPrompts: [OpenAIPrompt] = [
        .init(
            title: "Analyse Object • V3", // Updated version
            body: """
            Identify the main subject of the provided image (e.g., "Birch tree", "Vans Old Skool shoes", "Scott e-bike").
            Return a minified JSON object with exactly four keys: "title", "description", "stats", and "detailedSubjectDescription".

            {
              "title": "<Simple name for the card title, e.g., 'Vans Old Skool', 'Birch Tree', 'Mysterious Orb'>",
              "description": "<A fun, cheeky, or interesting fact/overview about the object for the card's text, max two sentences. e.g., 'A timeless skate classic known for its iconic sidestripe and sturdy build.'>",
              "stats": [
                { "category": "<attr1 name>", "value": "<value1>" },
                { "category": "<attr2 name>", "value": "<value2>" },
                { "category": "<attr3 name>", "value": "<value3>" },
                { "category": "<attr4 name>", "value": "<value4>" }
              ],
              "detailedSubjectDescription": "<A concise but visually rich phrase describing the main subject, essential for generating a new image of it. E.g., 'a pair of classic black and white Vans Old Skool sneakers with the iconic white leather sidestripe, sturdy canvas, and waffle outsole', or 'a majestic, snow-dusted birch tree standing tall against a pale winter sky', or 'a glowing, pulsating orb of unknown origin, crackling with energy'. Focus on appearance, key visual characteristics, and any defining features or colors. This description will directly feed into an image generation model.>"
            }

            Instructions for JSON content:
            • title: Keep it concise and appealing for a card game.
            • description: Max two sentences. Inject personality (fun, cheeky, intriguing).
            • stats: Exactly 4 items. Each "category" and "value" should be short (max 3 words, or ~20 chars). Values can be strings or numbers (as strings in the JSON).
            • detailedSubjectDescription: THIS IS CRITICAL. It MUST be a descriptive phrase that an image generation AI can use to create a compelling visual of the object. Be specific about form, color, texture, and context if relevant.
            • Return ONLY valid, minified JSON—no extra formatting, no markdown, no line breaks outside of the JSON string values themselves.
            """
        )
        // You can add more analysis prompt variations here
    ]

    // MARK: - Convenience
    var defaultImagePrompt: String { imagePrompts.first!.body } // This is now a template
    var defaultTextPrompt:  String { textPrompts.first!.body }

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

    /// Helper to get a specific prompt by title, useful for experimentation if you add UI
    func getPrompt(title: String, domain: OpenAIPromptDomain) -> OpenAIPrompt? {
        switch domain {
        case .image:
            return imagePrompts.first(where: { $0.title == title })
        case .text:
            return textPrompts.first(where: { $0.title == title })
        }
    }
}
