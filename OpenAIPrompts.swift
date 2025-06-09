
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
      • visualTraits – concise, comma-separated appearance notes (shape, colors, textures)
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
        Invent a short, whimsical, creature-like name for a monster based on {{subject}}. Aim for a playful, Pokémon-esque style (e.g., "Bubblor", "Fiznox", "Sparkleef", "Clunkett") rather than descriptive or imposing names (e.g., "Frost Prowler", "Steel Guardian"). The name should be a single, unique, pronounceable word. Avoid existing Pokémon names.
        """,

        .artPrompt : """
        A cute monster. {{visualTraits}}. Simple background.
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

