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
    // New colors for two-part info labels
    var infoLabelCategoryBackground: Color
    var infoLabelValueBackground: Color
}

struct CardThemes {

static let themeOne = CardTheme( // Was themeSix, renamed to themeOne
        name: "Vintage Paper",
        cardBackground: Color(hex: "#F1E1BE"),      // Creamy Beige
        innerFrameLine: Color(hex: "#BE5A46"),      // Terracotta Red
        titleText: Color(hex: "#232334"),           // Dark Slate Gray
        imageFrameBackground: Color(hex: "#BE5A46"), // Terracotta Red
        infoBarBackground: Color(hex: "#BE5A46"),    // Terracotta Red
        tagBackground: Color(hex: "#232334"),       // Dark Slate Gray
        tagText: Color(hex: "#F1E1BE"),           // Creamy Beige
        bottomContainerBackground: Color(hex: "#BE5A46"), // Terracotta Red
        fingerprintBackground: Color(hex: "#D3A993"), // Lighter Terracotta
        fingerprintSymbol: Color(hex: "#232334"),   // Dark Slate Gray
        idNumberText: Color(hex: "#232334"),       // Dark Slate Gray
        idNameText: Color(hex: "#232334"),         // Dark Slate Gray
        scanToText: Color(hex: "#232334"),         // Dark Slate Gray
        qrCodePlaceholderBackground: Color(hex: "#D3C5A9"), // Muted Beige
        qrCodeIcon: Color(hex: "#232334"),           // Dark Slate Gray
        infoLabelCategoryBackground: Color(hex: "#232334"), // Dark Slate Gray
        infoLabelValueBackground: Color(hex: "#A04B3A")    // Darker Terracotta
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
        scanToText: Color(hex: "D2691E"), // Burnt Orange
        qrCodePlaceholderBackground: Color(hex: "FFE5B4"), // Light Orange (Peach)
        qrCodeIcon: Color(hex: "D2691E"), // Burnt Orange
        infoLabelCategoryBackground: Color(hex: "C84B31"), // Dark Orange
        infoLabelValueBackground: Color(hex: "FFA500")    // Orange (Corrected comment)
    )

    static let themeThree = CardTheme( // Was themeSeven, renamed to themeTwo
        name: "Oceanic Deep",
        cardBackground: Color(hex: "#0A1931"),      // Very Dark Blue
        innerFrameLine: Color(hex: "#185ADB"),      // Bright Royal Blue
        titleText: Color(hex: "#E8F0F2"),           // Off-White/Light Cyan
        imageFrameBackground: Color(hex: "#1D2D50"), // Dark Slate Blue
        infoBarBackground: Color(hex: "#185ADB"),    // Bright Royal Blue
        tagBackground: Color(hex: "#E8F0F2"),       // Off-White/Light Cyan
        tagText: Color(hex: "#0A1931"),           // Very Dark Blue
        bottomContainerBackground: Color(hex: "#1D2D50"), // Dark Slate Blue
        fingerprintBackground: Color(hex: "#274A78"), // Medium Dark Blue
        fingerprintSymbol: Color(hex: "#E8F0F2"),   // Off-White/Light Cyan
        idNumberText: Color(hex: "#E8F0F2"),       // Off-White/Light Cyan
        idNameText: Color(hex: "#A2BBDD"),         // Light Steel Blue
        scanToText: Color(hex: "#E8F0F2"),         // Off-White/Light Cyan
        qrCodePlaceholderBackground: Color(hex: "#1D2D50"), // Dark Slate Blue
        qrCodeIcon: Color(hex: "#E8F0F2"),           // Off-White/Light Cyan
        infoLabelCategoryBackground: Color(hex: "#E8F0F2"), // Off-White/Light Cyan
        infoLabelValueBackground: Color(hex: "#185ADB")    // Bright Royal Blue
    )

    static let themeFour = CardTheme( // Was themeEight, renamed to themeThree
        name: "Emerald Isle",
        cardBackground: Color(hex: "#104F55"),      // Dark Teal Green
        innerFrameLine: Color(hex: "#58B09C"),      // Sea Green
        titleText: Color(hex: "#F7F7F7"),           // Very Light Gray/Almost White
        imageFrameBackground: Color(hex: "#1A5E63"), // Medium Teal Green
        infoBarBackground: Color(hex: "#58B09C"),    // Sea Green
        tagBackground: Color(hex: "#F7F7F7"),       // Very Light Gray
        tagText: Color(hex: "#104F55"),           // Dark Teal Green
        bottomContainerBackground: Color(hex: "#1A5E63"), // Medium Teal Green
        fingerprintBackground: Color(hex: "#2C7873"), // Slightly Lighter Teal
        fingerprintSymbol: Color(hex: "#F7F7F7"),   // Very Light Gray
        idNumberText: Color(hex: "#F7F7F7"),       // Very Light Gray
        idNameText: Color(hex: "#A0D2DB"),         // Light Cyan Blue
        scanToText: Color(hex: "#F7F7F7"),         // Very Light Gray
        qrCodePlaceholderBackground: Color(hex: "#1A5E63"), // Medium Teal Green
        qrCodeIcon: Color(hex: "#F7F7F7"),           // Very Light Gray
        infoLabelCategoryBackground: Color(hex: "#F7F7F7"), // Very Light Gray
        infoLabelValueBackground: Color(hex: "#58B09C")    // Sea Green
    )
    
    static let availableCardThemes: [CardTheme] = [themeOne, themeTwo, themeThree, themeFour]
}

// Note: Ensure the Color(hex:) extension is available and working.
// It seems to be present in the existing UIColors.swift file.
