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


// 1. Define the structure for a theme's color palette
struct ThemePalette {
    // Screen & Global
    var screenBackground: Color
    var frameOutline: Color

    // Title Block (and App Header)
    var titleText: Color
    var titleFrameBackground: Color // Can be reused for App Header

    // Image Block
    var imagePlaceholderBackground: Color

    // Description Block
    var descriptionText: Color
    var descriptionBoxBackground: Color

    // Stats Block & Components (and Camera Controls Container)
    var statsContainerBackground: Color // Can be reused for Camera Controls Container
    var statsHeaderText: Color
    var statsHeaderBackground: Color
    var statCategoryText: Color
    var statValueText: Color
    var statItemBackground: Color
    
    // Action Buttons
    var buttonText: Color
    var buttonBackground: Color // General button background
    var buttonOutline: Color
    
    // Specific Action Button Colors (Added for CameraView customization)
    var primaryActionButtonBackground: Color?   // Optional, for "Analyze"/"Confirm"
    var secondaryActionButtonBackground: Color? // Optional, for "New Picture"
}

// 2. Define different themes
enum ThemeType: CaseIterable, Identifiable {
    case snapFactsTheme, defaultYellow, vibrantBlue, forestGreen, monochrome, cameraTheme // ADDED .snapFactsTheme as the new primary
    
    var id: Self { self }

    var palette: ThemePalette {
        switch self {
        case .snapFactsTheme:
            return ThemePalette(
                screenBackground: Color.snapFactsBeige.opacity(0.7), // A slightly transparent beige for the overall screen
                frameOutline: Color.snapFactsDark, // Dark outline for the main card

                titleText: Color.snapFactsDark,
                titleFrameBackground: Color.snapFactsRedOrange,

                imagePlaceholderBackground: Color.snapFactsRedOrange.opacity(0.8),

                descriptionText: Color.snapFactsDark,
                descriptionBoxBackground: Color.snapFactsRedOrange,

                statsContainerBackground: Color.snapFactsRedOrange,
                statsHeaderText: Color.snapFactsBeige, // Beige text on red-orange header
                statsHeaderBackground: Color.snapFactsDark, // Dark header background for contrast
                statCategoryText: Color.snapFactsDark,
                statValueText: Color.snapFactsDark,
                statItemBackground: Color.snapFactsBeige.opacity(0.7), // Lighter beige for stat items
                
                buttonText: Color.snapFactsBeige,
                buttonBackground: Color.snapFactsDark, // Dark buttons
                buttonOutline: Color.snapFactsRedOrange, // Red-orange outline for buttons
                
                primaryActionButtonBackground: Color.snapFactsDark,
                secondaryActionButtonBackground: Color.snapFactsDark.opacity(0.8)
            )
        // NOTE: The 'case .defaultYellow:' below is the correct continuation of the primary switch
        case .defaultYellow:
            return ThemePalette(
                screenBackground: Color.yellow.opacity(0.4),
                frameOutline: Color.orange.opacity(0.6),
                titleText: .black,
                titleFrameBackground: Color.yellow.opacity(0.2),
                imagePlaceholderBackground: Color.yellow.opacity(0.25),
                descriptionText: .black,
                descriptionBoxBackground: Color.yellow.opacity(0.15),
                statsContainerBackground: Color.yellow.opacity(0.2),
                statsHeaderText: .black,
                statsHeaderBackground: .orange.opacity(0.7),
                statCategoryText: .black,
                statValueText: .black,
                statItemBackground: .orange.opacity(0.6),
                buttonText: .black,
                buttonBackground: .orange.opacity(0.5),
                buttonOutline: .orange.opacity(0.7),
                primaryActionButtonBackground: .orange.opacity(0.6), // Example
                secondaryActionButtonBackground: .orange.opacity(0.4) // Example
            )
        case .vibrantBlue:
            return ThemePalette(
                screenBackground: Color.blue.opacity(0.3),
                frameOutline: Color.blue.opacity(0.8),
                titleText: .white,
                titleFrameBackground: Color.blue.opacity(0.15),
                imagePlaceholderBackground: Color.blue.opacity(0.2),
                descriptionText: .white,
                descriptionBoxBackground: Color.blue.opacity(0.1),
                statsContainerBackground: Color.blue.opacity(0.15),
                statsHeaderText: .white,
                statsHeaderBackground: Color.blue.opacity(0.6),
                statCategoryText: .white,
                statValueText: .white,
                statItemBackground: Color.blue.opacity(0.5),
                buttonText: .white,
                buttonBackground: Color.blue.opacity(0.4),
                buttonOutline: Color.blue.opacity(0.7),
                primaryActionButtonBackground: Color.blue.opacity(0.5),
                secondaryActionButtonBackground: Color.blue.opacity(0.3)
            )
        case .forestGreen:
            return ThemePalette(
                screenBackground: Color.green.opacity(0.3),
                frameOutline: Color.green.opacity(0.8),
                titleText: .white,
                titleFrameBackground: Color.green.opacity(0.15),
                imagePlaceholderBackground: Color.green.opacity(0.2),
                descriptionText: .white,
                descriptionBoxBackground: Color.green.opacity(0.1),
                statsContainerBackground: Color.green.opacity(0.15),
                statsHeaderText: .white,
                statsHeaderBackground: Color.green.opacity(0.6),
                statCategoryText: .white,
                statValueText: .white,
                statItemBackground: Color.green.opacity(0.5),
                buttonText: .white,
                buttonBackground: Color.green.opacity(0.4),
                buttonOutline: Color.green.opacity(0.7),
                primaryActionButtonBackground: Color.green.opacity(0.5),
                secondaryActionButtonBackground: Color.green.opacity(0.3)
            )
        case .monochrome:
            return ThemePalette(
                screenBackground: .black,
                frameOutline: .gray,
                titleText: .white,
                titleFrameBackground: Color(white: 0.15),
                imagePlaceholderBackground: Color(white: 0.2),
                descriptionText: .white,
                descriptionBoxBackground: Color(white: 0.1),
                statsContainerBackground: Color(white: 0.15),
                statsHeaderText: .white,
                statsHeaderBackground: Color(white: 0.3),
                statCategoryText: .white,
                statValueText: .white,
                statItemBackground: Color(white: 0.25),
                buttonText: .white,
                buttonBackground: Color(white: 0.2),
                buttonOutline: .gray,
                primaryActionButtonBackground: Color(white: 0.25),
                secondaryActionButtonBackground: Color(white: 0.15)
            )
        case .cameraTheme: // This case was missing from your enum declaration
            return ThemePalette(
                screenBackground: .clear, // Camera feed shows through this
                frameOutline: .white.opacity(0.6),

                titleText: .white, // For "Snap Facts" text
                titleFrameBackground: .black.opacity(0.45), // Semi-transparent for "Snap Facts" bar

                imagePlaceholderBackground: .clear, // Not used for framing in CameraView
                descriptionText: .white, // Not used for framing in CameraView
                descriptionBoxBackground: .clear, // Not used for framing in CameraView

                statsContainerBackground: .black.opacity(0.45), // Semi-transparent for controls bar
                statsHeaderText: .white, // Not used here
                statsHeaderBackground: .clear, // Not used here
                statCategoryText: .white, // Not used here
                statValueText: .white, // Not used here
                statItemBackground: .clear, // Not used here
                
                buttonText: .white, // General button text for camera view
                buttonBackground: Color.white.opacity(0.2), // Fallback if specific action colors aren't used
                buttonOutline: Color.white.opacity(0.4),

                // Specific action colors for camera buttons
                primaryActionButtonBackground: Color.blue.opacity(0.7),   // For "Analyze" / "Confirm"
                secondaryActionButtonBackground: Color.gray.opacity(0.6) // For "New Picture"
            )
        }
    }
}

// 3. ThemeManager to handle current theme selection and notify views of changes
class ThemeManager: ObservableObject {
    @Published var currentThemeType: ThemeType
    
    // ADDED Initializer to set a default or specific initial theme
    init(initialTheme: ThemeType = .snapFactsTheme) { // Set .snapFactsTheme as the default
        self.currentThemeType = initialTheme
    }
    
    var currentPalette: ThemePalette {
        currentThemeType.palette
    }
    
    func cycleTheme() {
        // Exclude cameraTheme from general cycling, if desired.
        // If cameraTheme should be part of the cycle, remove the filter.
        let allThemes = ThemeType.allCases.filter { $0 != .cameraTheme }
        
        guard !allThemes.isEmpty else { // Ensure there are themes to cycle through
            if ThemeType.allCases.contains(.defaultYellow) {
                currentThemeType = .defaultYellow // Fallback to defaultYellow if allThemes is empty
            } else if let firstAvailable = ThemeType.allCases.first {
                currentThemeType = firstAvailable // Fallback to the very first theme if defaultYellow isn't there
            }
            return
        }
        
        guard let currentIndex = allThemes.firstIndex(of: currentThemeType) else {
            // If current theme is not in the cyclable list (e.g., it's cameraTheme),
            // start cycling from the first theme in the filtered list.
            currentThemeType = allThemes.first ?? .defaultYellow
            return
        }
        
        let nextIndex = (currentIndex + 1) % allThemes.count
        currentThemeType = allThemes[nextIndex]
    }
}
