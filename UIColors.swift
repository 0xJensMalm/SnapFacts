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
        name: "Midnight Bloom",
        cardBackground: Color(hex: "#1A0F2A"), // Very Dark Purple/Blue
        innerFrameLine: Color(hex: "#B08D57").opacity(0.8), // Muted Gold/Bronze
        titleText: Color(hex: "#F0E6D2"), // Off-White/Light Gold
        imageFrameBackground: Color(hex: "#3D2C5C"), // Dark Grayish Purple
        infoBarBackground: Color(hex: "#4A3769"), // Deep Purple
        tagBackground: Color(hex: "#B08D57"), // Muted Gold/Bronze
        tagText: Color(hex: "#1A0F2A"), // Dark background for contrast on gold
        bottomContainerBackground: Color(hex: "#3D2C5C"), // Dark Grayish Purple
        fingerprintBackground: Color(hex: "#5C4B7E"), // Slightly Lighter Dark Purple
        fingerprintSymbol: Color(hex: "#F0E6D2"), // Off-White/Light Gold
        idNumberText: Color(hex: "#F0E6D2"), // Off-White/Light Gold
        idNameText: Color(hex: "#A094B7"), // Light Grayish Purple
        scanToText: Color(hex: "#B08D57"), // Muted Gold/Bronze
        qrCodePlaceholderBackground: Color(hex: "#5C4B7E"), // Slightly Lighter Dark Purple
        qrCodeIcon: Color(hex: "#F0E6D2") // Off-White/Light Gold
    )

    static let themeTwo = CardTheme(
        name: "Sunset Glow",
        cardBackground: Color(hex: "#E67E22"), // Deep Orange
        innerFrameLine: Color(hex: "#F1C40F").opacity(0.9), // Light Yellow/Gold
        titleText: Color(hex: "#4A2B0F"), // Dark Brown
        imageFrameBackground: Color(hex: "#FAD7A0"), // Light Orange/Peach
        infoBarBackground: Color(hex: "#C0392B"), // Rich Red
        tagBackground: Color(hex: "#F1C40F"), // Yellow
        tagText: Color(hex: "#4A2B0F"), // Dark Brown
        bottomContainerBackground: Color(hex: "#FAD7A0"), // Light Orange/Peach
        fingerprintBackground: Color(hex: "#D35400"), // Medium Orange
        fingerprintSymbol: Color(hex: "#4A2B0F"), // Dark Brown
        idNumberText: Color(hex: "#4A2B0F"), // Dark Brown
        idNameText: Color(hex: "#784212"), // Medium Brown
        scanToText: Color(hex: "#4A2B0F"), // Dark Brown
        qrCodePlaceholderBackground: Color(hex: "#D35400"), // Medium Orange
        qrCodeIcon: Color(hex: "#FDEBD0") // Light Yellow/Cream
    )

    static let themeThree = CardTheme(
        name: "Forest Canopy",
        cardBackground: Color(hex: "#224F36"), // Deep Forest Green
        innerFrameLine: Color(hex: "#D4C1A9").opacity(0.8), // Light Beige/Tan
        titleText: Color(hex: "#F5F5DC"), // Cream/Off-White
        imageFrameBackground: Color(hex: "#556B2F"), // Medium Olive Green
        infoBarBackground: Color(hex: "#5D4037"), // Dark Brown
        tagBackground: Color(hex: "#D4C1A9"), // Light Beige/Tan
        tagText: Color(hex: "#3E2723"), // Darker Brown for contrast
        bottomContainerBackground: Color(hex: "#556B2F"), // Medium Olive Green
        fingerprintBackground: Color(hex: "#6B8E23"), // Lighter Olive Green
        fingerprintSymbol: Color(hex: "#F5F5DC"), // Cream/Off-White
        idNumberText: Color(hex: "#F5F5DC"), // Cream/Off-White
        idNameText: Color(hex: "#A1887F"), // Light Brownish Gray
        scanToText: Color(hex: "#F5F5DC"), // Cream/Off-White
        qrCodePlaceholderBackground: Color(hex: "#6B8E23"), // Lighter Olive Green
        qrCodeIcon: Color(hex: "#F5F5DC") // Cream/Off-White
    )

    static let themeFour = CardTheme(
        name: "Arctic Frost",
        cardBackground: Color(hex: "#EAF2F8"), // Very Light Blue/Almost White
        innerFrameLine: Color(hex: "#A6ACAF").opacity(0.7), // Medium Silver/Gray
        titleText: Color(hex: "#2C3E50"), // Dark Charcoal Gray
        imageFrameBackground: Color(hex: "#D5D8DC"), // Light Silver/Gray
        infoBarBackground: Color(hex: "#85929E"), // Cool Blue-Gray
        tagBackground: Color(hex: "#AED6F1"), // Icy Blue
        tagText: Color(hex: "#212F3C"), // Darker Blue-Gray for contrast
        bottomContainerBackground: Color(hex: "#D5D8DC"), // Light Silver/Gray
        fingerprintBackground: Color(hex: "#B2BABB"), // Medium Silver/Gray
        fingerprintSymbol: Color(hex: "#2C3E50"), // Dark Charcoal Gray
        idNumberText: Color(hex: "#2C3E50"), // Dark Charcoal Gray
        idNameText: Color(hex: "#566573"), // Medium Gray
        scanToText: Color(hex: "#2C3E50"), // Dark Charcoal Gray
        qrCodePlaceholderBackground: Color(hex: "#B2BABB"), // Medium Silver/Gray
        qrCodeIcon: Color(hex: "#FFFFFF") // White
    )

    static let themeFive = CardTheme(
        name: "Retro Pop",
        cardBackground: Color(hex: "#1ABC9C"), // Bright Teal
        innerFrameLine: Color(hex: "#E91E63").opacity(0.9), // Hot Pink
        titleText: Color(hex: "#F7DC6F"), // Electric Yellow
        imageFrameBackground: Color(hex: "#ECF0F1"), // Light Gray
        infoBarBackground: Color(hex: "#8E44AD"), // Dark Purple
        tagBackground: Color(hex: "#E91E63"), // Hot Pink
        tagText: Color(hex: "#F7DC6F"), // Electric Yellow
        bottomContainerBackground: Color(hex: "#ECF0F1"), // Light Gray
        fingerprintBackground: Color(hex: "#BDC3C7"), // Medium Gray
        fingerprintSymbol: Color(hex: "#F7DC6F"), // Electric Yellow
        idNumberText: Color(hex: "#F7DC6F"), // Electric Yellow
        idNameText: Color(hex: "#FFFFFF"), // White
        scanToText: Color(hex: "#E91E63"), // Hot Pink
        qrCodePlaceholderBackground: Color(hex: "#BDC3C7"), // Medium Gray
        qrCodeIcon: Color(hex: "#F7DC6F") // Electric Yellow
    )
    
    static let availableCardThemes: [CardTheme] = [themeOne, themeTwo, themeThree, themeFour, themeFive]
}

// Note: Ensure the Color(hex:) extension is available and working.
// It seems to be present in the existing UIColors.swift file.
