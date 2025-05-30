import SwiftUI

// 1. Define the structure for a theme's color palette
struct ThemePalette {
    // Screen & Global
    var screenBackground: Color
    var frameOutline: Color

    // Title Block
    var titleText: Color
    var titleFrameBackground: Color

    // Image Block
    var imagePlaceholderBackground: Color

    // Description Block
    var descriptionText: Color
    var descriptionBoxBackground: Color

    // Stats Block & Components
    var statsContainerBackground: Color
    var statsHeaderText: Color
    var statsHeaderBackground: Color
    var statCategoryText: Color
    var statValueText: Color
    var statItemBackground: Color
    
    // Action Buttons
    var buttonText: Color
    var buttonBackground: Color
    var buttonOutline: Color
}

// 2. Define different themes
enum ThemeType: CaseIterable, Identifiable {
    case defaultYellow, vibrantBlue, forestGreen, monochrome
    
    var id: Self { self }

    var palette: ThemePalette {
        switch self {
        case .defaultYellow: // "Background yellow, all container backgrounds: slightly lighter yellow etc."
            return ThemePalette(
                screenBackground: Color.yellow.opacity(0.4), // Base yellow background
                frameOutline: Color.orange.opacity(0.6),

                titleText: .black,
                titleFrameBackground: Color.yellow.opacity(0.2), // Lighter yellow

                imagePlaceholderBackground: Color.yellow.opacity(0.25), // Lighter yellow

                descriptionText: .black,
                descriptionBoxBackground: Color.yellow.opacity(0.15), // Lighter yellow

                statsContainerBackground: Color.yellow.opacity(0.2), // Lighter yellow
                statsHeaderText: .black,
                statsHeaderBackground: .orange.opacity(0.7),

                statCategoryText: .black,
                statValueText: .black,
                statItemBackground: .orange.opacity(0.6),
                
                buttonText: .black,
                buttonBackground: .orange.opacity(0.5),
                buttonOutline: .orange.opacity(0.7)
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
                buttonOutline: Color.blue.opacity(0.7)
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
                buttonOutline: Color.green.opacity(0.7)
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
                buttonOutline: .gray
            )
        }
    }
}

// 3. ThemeManager to handle current theme selection and notify views of changes
class ThemeManager: ObservableObject {
    @Published var currentThemeType: ThemeType = .defaultYellow
    
    var currentPalette: ThemePalette {
        currentThemeType.palette
    }
    
    func cycleTheme() {
        let allThemes = ThemeType.allCases
        guard let currentIndex = allThemes.firstIndex(of: currentThemeType) else {
            currentThemeType = allThemes.first ?? .defaultYellow
            return
        }
        let nextIndex = (currentIndex + 1) % allThemes.count
        currentThemeType = allThemes[nextIndex]
    }
}
