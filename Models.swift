// Models.swift

import Foundation

// ─────────────────────────────────────────────────────────────────
// MARK: – StatValue, CardStatItem, CardContent, AnalysisResult

/// Wraps either an integer or a string: used for stat values in a card.
enum StatValue: Decodable, Hashable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let strVal = try? container.decode(String.self) {
            self = .string(strVal)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected Int or String for StatValue"
            )
        }
    }
}

/// Convenience extension so you can do `value.displayString` in your SwiftUI views.
extension StatValue {
    var displayString: String {
        switch self {
        case .int(let i):
            return "\(i)"
        case .string(let s):
            return s
        }
    }
}

/// Represents one stat cell in a card (e.g. “PRICE: 60” or “COMFORT: High”).
struct CardStatItem: Identifiable, Hashable {
    let id = UUID()
    let category: String
    let value: StatValue
}

/// The fully‐assembled card data (title, description, image URL or name, plus stats).
/// Using `localImageName` to match the fix in CardGeneratorViewModel.
struct CardContent: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let localImageName: String  // This is the image URL string for the card image.
    let stats: [CardStatItem]
}

/// The JSON shape we expect back from Vision‐Chat analysis:
/// {
///   "title": "string",
///   "description": "string", // For the card's text
///   "stats": [ { "category": "string", "value": "string" }, … ], // Value is string, converted later
///   "detailedSubjectDescription": "string" // For generating the new image
/// }
struct AnalysisResult: Decodable {
    struct Stat: Decodable {
        let category: String
        let value: String // OpenAI will return numbers as strings if instructed; ViewModel will parse
    }
    let title: String
    let description: String
    let stats: [Stat]
    let detailedSubjectDescription: String // Essential for generating the new image
}

// ─────────────────────────────────────────────────────────────────
// MARK: – Sample Data (for previews or default CardView)

/// Instead of creating a separate file just for sample cards, we can define
/// one or more “static let” instances right here. Feel free to rename or
/// expand as needed. CardView’s initializer can refer to this.
enum SampleCardData {
    static let vansOldSkool = CardContent(
        id: "vans_old_skool_001",
        title: "VANS OLD SKOOL",
        description:
            "The Vans Old Skool: a timeless skate shoe with side stripe, durable canvas & suede upper, and signature waffle outsole. Iconic style meets everyday comfort.",
        localImageName: "https://images.vans.com/is/image/Vans/VN000D3HY28-HERO?$STANDARD_IMAGE$", // Example URL
        stats: [
            CardStatItem(category: "COMFORT",    value: .string("High")),
            CardStatItem(category: "DURABILITY", value: .string("Very High")),
            CardStatItem(category: "STYLE",      value: .string("Classic")),
            CardStatItem(category: "PRICE",      value: .int(60))
        ]
    )

    // You can add more “pre‐baked” CardContent instances here if you like:
    //
    // static let anotherExample = CardContent(
    //     id: "example_002",
    //     title: "ANOTHER EXAMPLE",
    //     description: "Some description here.",
    //     localImageName: "https://example.com/another_image.png",
    //     stats: [
    //         CardStatItem(category: "AWESOMENESS", value: .string("Max")),
    //         CardStatItem(category: "RARITY", value: .int(100))
    //     ]
    // )
}
