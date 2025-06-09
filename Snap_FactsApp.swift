import SwiftUI

@main
struct Snap_FactsApp: App {
    @StateObject private var snapDexManager = SnapDexManager()
    @StateObject private var themeManager = ThemeManager() // Assuming ThemeManager is still needed globally

    var body: some Scene {
        WindowGroup {
            SnapDexView()
                .environmentObject(snapDexManager)
                .environmentObject(themeManager) // Pass ThemeManager as well
        }
    }
}
