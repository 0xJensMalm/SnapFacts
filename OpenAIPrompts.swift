
//  OpenAIPrompts.swift
//  Stage-based pipeline → Pokémon-style trading cards
//  Steps: Image ➜ Analyse (JSON) ➜ Generate Title, Art Prompt, Stats JSON
//
//  ----------------------------------------------------------------------
//  HOW-TO TWEAK
//  •  Edit wording in `AnalysePrompt.text` or `CardRecipe.templates`.
//  •  Add/rename types → see `CardType` enum.
//  •  Change stats list → update `StatKey` enum + templates.
//  •  Call `OpenAIPrompts.shared.cardPrompt(_:with:)` to render.
//  ----------------------------------------------------------------------

import Foundation

// MARK: - Card Foundations

/// Allowed monster elemental classes – extend freely.
enum CardType: String, CaseIterable {
    case Natural, Tech, Fire, Water, Earth, Air, Electric, Spirit
}

/// Numeric attributes each monster will have.
fileprivate enum StatKey: String, CaseIterable { case strength = "Strength", stamina = "Stamina", agility = "Agility" }

// MARK: - Analyse-step Prompt (Image -> JSON)

struct AnalysePrompt {
    static let text = """
    You are a trading-card data bot.  Identify the PRIMARY subject of the user-supplied photo (e.g. "Birch tree", "Gaming mouse", "Coca-Cola can").
    
    Return ONE minified JSON object – no extra text – with exactly SIX keys:
      • subject  – short noun phrase, lowercase articles removed (e.g. "Birch tree", "Vans Old Skool shoes")
      • visualTraits – concise, comma-separated appearance notes (e.g., 'fluffy, white, with large blue eyes, often found in snowy plains' or 'metallic, sleek, with glowing red stripes, typically seen in futuristic cityscapes'). Include key physical characteristics and hints about its natural environment.
      • type      – best-fit among: Natural 🌿, Tech ⚙️, Fire 🔥, Water 💧, Earth 🧱, Air 💨, Electric ⚡️, Spirit 🫥 (case-sensitive, include the emoji in the value)
      • strength  – integer 0-100 (raw power)
      • stamina   – integer 0-100 (endurance)
      • agility   – integer 0-100 (speed/dexterity)
    """
}

// MARK: - Card Recipe (JSON -> three prompts)

/// JSON keys we expect back from the analyse step.
fileprivate enum PH: String, CaseIterable {
    case subject, visualTraits, type, strength, stamina, agility
}

struct CardRecipe {
    enum Part { case title, artPrompt, statsJSON }

    /// Core templates with inline placeholders {{placeholder}}
    private static let templates: [Part : String] = [
        .title : """
        The title should be the name of the {{subject}} adding Japanese-inspired suffixes or phonetic transformations to make it sound like a collectible monster. The result should be fun, pronounceable, and still hint at the original word. Examples include: ‘Fridgoko’, ‘Sodachu’, ‘Poweruplu’, ‘Microwavax’. Keep the names short (2–4 syllables) and mix in common Pokémon-style suffixes like -chu, -ko, -mon, -zu, -tan, -pu, -ra, -bo, or -nix. Output ONLY the name itself, without any other text or quotation marks.
        """,


        .artPrompt : """
        Digital painting in the style of a modern concept artist, consistent across all images. Generate only one image. Depict a single, primary subject: a whimsical creature inspired by {{visualTraits}}. The creature must be easily recognizable and the main focus. The creature is in its natural environment, which should be complementary but not distracting. The background must be clean, simple, and uncluttered. IMPORTANT: The generated image itself should NOT contain any frames, borders, or card-like elements; it should be a clean illustration of the subject in its environment, suitable for later placement onto a trading card. The overall artistic style should be cute, charming, with clear lines and appealing colors. Do not generate multiple sketches, variations, or panels.
        """,

        .statsJSON : { () -> String in
            // Build JSON template dynamically to avoid duplication
            var json = "{\"stats\":[{\"category\":\"Type\",\"value\":\"{{type}}\"}"
            for key in StatKey.allCases {
                json += ",{\\\"category\\\":\\\"\(key.rawValue)\\\",\\\"value\\\":\\\"{{\(key.rawValue.lowercased())}}\\\"}"
            }
            json += "]}"
            return "Return this EXACT minified JSON (single line, no spaces): \(json)"
        }()
    ]

    /// Render helper – replaces {{placeholders}} with analyse-JSON values
    static func render(part: Part, with data: [String:Any]) -> String {
        var out = templates[part]!
        for ph in PH.allCases {
            if let val = data[ph.rawValue] { out = out.replacingOccurrences(of: "{{\(ph.rawValue)}}", with: "\(val)") }
        }
        return out
    }
}

// MARK: - Prompt Registry (singleton)

final class OpenAIPrompts {
    static let shared = OpenAIPrompts(); private init() {}

    // MARK: Accessors
    var analysePrompt: String { AnalysePrompt.text }

    func cardPrompt(_ part: CardRecipe.Part, with analysisJSON: [String:Any]) -> String {
        CardRecipe.render(part: part, with: analysisJSON)
    }
}

