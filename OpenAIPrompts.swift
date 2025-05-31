// OpenAIPrompts.swift

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
            title: "Card Art • V2",
            body: """
                  Create a play-card style illustration that focuses on the main subject of the image (for example: “Birch tree”, “Man with a hat”, “Corona bottle”, “Scott e-bike” - make sure to get the correct characteristics and details like color etc.).  
                  • Emphasize the subject with bold lines, clean edges, and vibrant colors.  
                  • Use a minimal background so the subject stands out.  
                  • Render it like a collectible card (flat shading, stylized shape, clear outline).  
                  """
        )
    ]

    private(set) var textPrompts: [OpenAIPrompt] = [
        .init(
            title: "Analyse Product • V2",
            body: """
                  Identify the main subject of the provided image (e.g., "Birch tree", "Man with a hat", "Corona bottle", "Scott e-bike"). 
                  Return a minified JSON object with exactly four keys:

                  {
                    "title": "<main subject>",                          // Simple name, e.g. "Birch tree"
                    "description": "<fun fact about the object, max two sentences>", 
                    "stats": [
                      { "category": "age",            "value": "<approx 10 years>" },
                      { "category": "material type",  "value": "<rubber>" },
                      { "category": "species",        "value": "<human>" },
                      { "category": "<another cat>",  "value": "<value>" }
                    ]
                  }
                  These are just example categories and values. You need to find new ones which fits the image, dont be afraid to be cheeky or use humour. 

                  • Title: keep it very simple (e.g. “Birch tree”, “Man with a hat”, “Scott e-bike”).  
                  • Description: a single fun fact about that object (max two sentences).  
                  • Stats array: exactly 4 items.  
                    – Each “category” and each “value” must use at most three words, and no more than 20 characters total.  
                    – Example categories: age, material type, species, latin name, color, brand, model, etc.  
                  • Return ONLY valid, minified JSON—no extra formatting, no line breaks.
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
