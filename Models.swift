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
struct CardContent: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let localImageName: String    // can be either a local asset name or a remote URL string
    let stats: [CardStatItem]
}

/// The JSON shape we expect back from Vision‐Chat analysis:
/// {
///   "title": "string",
///   "description": "string",
///   "stats": [ { "category": "string", "value": "string or number" }, … ]
/// }
struct AnalysisResult: Decodable {
    struct Stat: Decodable {
        let category: String
        let value: String
    }
    let title: String
    let description: String
    let stats: [Stat]
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
        localImageName: "https://example.com/images/vans_old_skool.png",
        stats: [
            CardStatItem(category: "COMFORT",    value: .string("High")),
            CardStatItem(category: "DURABILITY", value: .string("Very High")),
            CardStatItem(category: "STYLE",      value: .string("Classic")),
            CardStatItem(category: "PRICE",      value: .int(60))
        ]
    )

    // You can add more “pre‐baked” CardContent instances here if you like:
    //
    // static let airForceOne = CardContent(
    //     id: "nike_air_force_one_001",
    //     title: "NIKE AIR FORCE 1",
    //     description: "The iconic Nike Air Force 1 basketball sneaker, originally released in 1982...",
    //     localImageName: "nike_air_force_one_asset",
    //     stats: [
    //         CardStatItem(category: "COMFORT",    value: .string("Moderate")),
    //         CardStatItem(category: "TRACTION",   value: .string("Excellent")),
    //         CardStatItem(category: "BRANDING",   value: .string("Iconic")),
    //         CardStatItem(category: "PRICE",      value: .int(90))
    //     ]
    // )
}
