import SwiftUI

struct CardBackView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            themeManager.currentTheme.cardBackground // Background color from the current theme

            Image("snapFacts") // Assuming your logo asset is named this
                .resizable()
                .scaledToFit()
                .padding(UIConfigLayout.globalVerticalSpacing * 2) // Generous padding around the logo
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it fills the card space
        .cornerRadius(UIConfigLayout.defaultFrameCornerRadius * 1.5) // Match front card's outer corner radius
        .overlay(
            RoundedRectangle(cornerRadius: UIConfigLayout.defaultFrameCornerRadius * 1.5)
                .stroke(themeManager.currentTheme.innerFrameLine, lineWidth: UIConfigLayout.frameOutlineWidth * 1.5) // Outline using current theme's inner frame line color // Outline using logo's dark color
        )
    }
}

struct CardBackView_Previews: PreviewProvider {
    static var previews: some View {
        CardBackView()
            .environmentObject(ThemeManager())
            .padding()
            .previewLayout(.sizeThatFits)
            .frame(width: 300, height: 450)
    }
}
