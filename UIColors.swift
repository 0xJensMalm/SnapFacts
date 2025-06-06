import SwiftUI

// Snap Facts Brand Colors (derived from logo - user provided)
extension Color {
    static let snapFactsBeige = Color(hex: "#F8E5BE") // Dutch white (tan fill)
    static let snapFactsDark = Color(hex: "#22231E")  // Eerie black
    static let snapFactsRedOrange = Color(hex: "#C8553F") // Jasper (red boxes)
    // Additional provided colors if needed later:
    // static let snapFactsChestnut = Color(hex: "#904636")
    // static let snapFactsBattleshipGray = Color(hex: "#7D7969")
}

// Helper to initialize Color from hex string
// (Ensure this or a similar helper exists if you use hex strings for colors)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - CardView Specific Themes

struct CardTheme: Identifiable {
    let id = UUID()
    var name: String

    // Overall Card
    var cardBackground: Color
    var innerFrameLine: Color

    // Header
    var titleText: Color
    
    // Image Area
    var imageFrameBackground: Color // Background for the image placeholder ZStack

    // Info Bar
    var infoBarBackground: Color
    var tagBackground: Color
    var tagText: Color

    // Bottom Section
    // Left Container (FP, ID, Name)
    var bottomContainerBackground: Color // New container for FP, ID, Name
    var fingerprintBackground: Color
    var fingerprintSymbol: Color // For "FP" text
    var idNumberText: Color
    var idNameText: Color
    
    // Right Container (QR Code)
    var scanToText: Color
    var qrCodePlaceholderBackground: Color
    var qrCodeIcon: Color
}

struct CardThemes {
    static let themeOne = CardTheme(
        name: "Modern Graphite",
        cardBackground: Color(hex: "#F5F5F5"), // Light Gray
        innerFrameLine: Color(hex: "#BDBDBD").opacity(0.7), // Medium Gray
        titleText: Color(hex: "#212121"), // Almost Black
        imageFrameBackground: Color(hex: "#E0E0E0"), // Lighter Gray
        infoBarBackground: Color(hex: "#424242"), // Dark Gray
        tagBackground: Color(hex: "#FFC107"), // Amber
        tagText: Color(hex: "#212121"), // Almost Black
        bottomContainerBackground: Color(hex: "#E0E0E0"), // Lighter Gray (same as image frame)
        fingerprintBackground: Color(hex: "#BDBDBD"), // Medium Gray
        fingerprintSymbol: Color(hex: "#424242"), // Dark Gray
        idNumberText: Color(hex: "#212121"), // Almost Black
        idNameText: Color(hex: "#616161"), // Medium-Dark Gray
        scanToText: Color(hex: "#424242"), // Dark Gray
        qrCodePlaceholderBackground: Color(hex: "#757575"), // Medium-Dark Gray
        qrCodeIcon: Color(hex: "#FFFFFF") // White
    )

    static let themeTwo = CardTheme(
        name: "Oceanic Teal",
        cardBackground: Color(hex: "#E0F7FA"), // Very Light Cyan
        innerFrameLine: Color(hex: "#4DD0E1").opacity(0.8), // Medium Cyan
        titleText: Color(hex: "#004D40"), // Dark Teal
        imageFrameBackground: Color(hex: "#B2EBF2"), // Light Cyan
        infoBarBackground: Color(hex: "#00796B"), // Teal
        tagBackground: Color(hex: "#FFD180"), // Light Orange/Amber
        tagText: Color(hex: "#004D40"), // Dark Teal
        bottomContainerBackground: Color(hex: "#B2EBF2"), // Light Cyan (same as image frame)
        fingerprintBackground: Color(hex: "#80DEEA"), // Light-Medium Cyan
        fingerprintSymbol: Color(hex: "#004D40"), // Dark Teal
        idNumberText: Color(hex: "#004D40"), // Dark Teal
        idNameText: Color(hex: "#006064"), // Slightly Lighter Dark Teal
        scanToText: Color(hex: "#00796B"), // Teal
        qrCodePlaceholderBackground: Color(hex: "#26A69A"), // Medium Teal
        qrCodeIcon: Color(hex: "#E0F7FA") // Very Light Cyan
    )
    
    static let availableCardThemes: [CardTheme] = [themeOne, themeTwo]
}

// Note: Ensure the Color(hex:) extension is available and working.
// It seems to be present in the existing UIColors.swift file.
