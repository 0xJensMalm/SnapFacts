import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            // Updated to correctly initialize CardView for preview purposes
            CardView(cardContent: SampleCardData.vansOldSkool, isFromSnapDex: false)
                .environmentObject(SnapDexManager())
                .environmentObject(ThemeManager())
        }
        .padding() // Optional: add padding around the card view
    }
}
