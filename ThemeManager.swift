import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var currentThemeIndex: Int = 0
    // Initialize with the first theme from CardThemes
    @Published var currentTheme: CardTheme = CardThemes.availableCardThemes[0] 

    // Store the array of available themes
    let themes: [CardTheme] = CardThemes.availableCardThemes

    init() {
        // Potential future init logic: load saved theme preference, etc.
        // For now, it defaults to the first theme.
        print("ThemeManager initialized. Current theme: \(currentTheme.name)")
    }

    func cycleTheme() {
        currentThemeIndex = (currentThemeIndex + 1) % themes.count
        currentTheme = themes[currentThemeIndex]
        print("Cycled theme. New theme: \(currentTheme.name)")
    }

    // Optional: function to set a specific theme by name or ID if needed later
    // func setTheme(byName name: String) {
    //     if let index = themes.firstIndex(where: { $0.name == name }) {
    //         currentThemeIndex = index
    //         currentTheme = themes[index]
    //     }
    // }
}
