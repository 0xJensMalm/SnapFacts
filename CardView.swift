import SwiftUI

struct CardStatItem: Identifiable {
    let id = UUID()
    var category: String
    var value: Int
}

struct CardView: View {
    @StateObject var themeManager = ThemeManager() // Manages theme state

    // Sample Data
    let cardTitle: String = "VANS OLD"
    let cardImagePlaceholderIconName: String = "photo.fill"
    let cardDescription: String = "An old shoe that never goes out of style. Always iconic."
    let stats: [CardStatItem] = [
        CardStatItem(category: "COMFORT", value: 84),
        CardStatItem(category: "GRIP", value: 79),
        CardStatItem(category: "STYLE", value: 92),
        CardStatItem(category: "DURABILITY", value: 88)
    ]

    var body: some View {
        ZStack {
            themeManager.currentPalette.screenBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .center, spacing: UIConfigLayout.globalVerticalSpacing) {

                    // MARK: - Title Block
                    Text(cardTitle)
                        .font(UIConfigLayout.titleFont)
                        .foregroundColor(themeManager.currentPalette.titleText)
                        .multilineTextAlignment(.center)
                        .padding(UIConfigLayout.titleFrameInternalPadding)
                        .frame(maxWidth: .infinity)
                        .background(themeManager.currentPalette.titleFrameBackground)
                        .cornerRadius(UIConfigLayout.defaultFrameCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConfigLayout.defaultFrameCornerRadius)
                                .stroke(themeManager.currentPalette.frameOutline, lineWidth: UIConfigLayout.frameOutlineWidth)
                        )

                    // MARK: - Image Block
                    Rectangle()
                        .fill(themeManager.currentPalette.imagePlaceholderBackground)
                        .aspectRatio(UIConfigLayout.imageAspectRatio, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(UIConfigLayout.defaultFrameCornerRadius)
                        .overlay(
                            Image(systemName: cardImagePlaceholderIconName)
                                .resizable().scaledToFit().frame(width: 50, height: 50) // Slightly smaller icon
                                .foregroundColor(Color.black.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConfigLayout.defaultFrameCornerRadius)
                                .stroke(themeManager.currentPalette.frameOutline, lineWidth: UIConfigLayout.frameOutlineWidth)
                        )

                    // MARK: - Description Block
                    Text(cardDescription)
                        .font(UIConfigLayout.descriptionFont)
                        .foregroundColor(themeManager.currentPalette.descriptionText)
                        .multilineTextAlignment(.center)
                        .padding(UIConfigLayout.descriptionBoxInternalPadding)
                        .frame(maxWidth: .infinity)
                        .background(themeManager.currentPalette.descriptionBoxBackground)
                        .cornerRadius(UIConfigLayout.defaultFrameCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConfigLayout.defaultFrameCornerRadius)
                                .stroke(themeManager.currentPalette.frameOutline, lineWidth: UIConfigLayout.frameOutlineWidth)
                        )

                    // MARK: - Stats Block
                    VStack(spacing: UIConfigLayout.statsInternalElementsSpacing) {
                        Text("STATS") // "STATS" Header Bar
                            .font(UIConfigLayout.statsHeaderFont)
                            .foregroundColor(themeManager.currentPalette.statsHeaderText)
                            .padding(UIConfigLayout.statsHeaderInternalPadding)
                            .background(themeManager.currentPalette.statsHeaderBackground)
                            .cornerRadius(UIConfigLayout.statsHeaderCornerRadius)

                        LazyVGrid( // Stats Grid (Smaller Items)
                            columns: [GridItem(.flexible(), spacing: UIConfigLayout.statsGridSpacing),
                                      GridItem(.flexible(), spacing: UIConfigLayout.statsGridSpacing)],
                            spacing: UIConfigLayout.statsGridSpacing
                        ) {
                            ForEach(stats) { statItem in
                                IndividualStatView(category: statItem.category, value: statItem.value)
                            }
                        }

                        // New Buttons HStack
                        HStack(spacing: UIConfigLayout.buttonsHStackSpacing) {
                            Button("Vibe") {
                                print("Vibe button tapped") // Placeholder action
                            }
                            .font(UIConfigLayout.actionButtonFont)
                            .padding(UIConfigLayout.actionButtonPadding)
                            .foregroundColor(themeManager.currentPalette.buttonText)
                            .frame(maxWidth: .infinity)
                            .background(themeManager.currentPalette.buttonBackground)
                            .cornerRadius(UIConfigLayout.actionButtonCornerRadius)
                            .overlay(RoundedRectangle(cornerRadius: UIConfigLayout.actionButtonCornerRadius)
                                .stroke(themeManager.currentPalette.buttonOutline, lineWidth: UIConfigLayout.actionButtonOutlineWidth))
                            
                            Button("Card Type") {
                                themeManager.cycleTheme() // Cycles to the next theme
                            }
                            .font(UIConfigLayout.actionButtonFont)
                            .padding(UIConfigLayout.actionButtonPadding)
                            .foregroundColor(themeManager.currentPalette.buttonText)
                            .frame(maxWidth: .infinity)
                            .background(themeManager.currentPalette.buttonBackground)
                            .cornerRadius(UIConfigLayout.actionButtonCornerRadius)
                            .overlay(RoundedRectangle(cornerRadius: UIConfigLayout.actionButtonCornerRadius)
                                .stroke(themeManager.currentPalette.buttonOutline, lineWidth: UIConfigLayout.actionButtonOutlineWidth))
                        }
                        .padding(.top, 5) // A little space above the buttons
                    }
                    .padding(UIConfigLayout.statsContainerInternalPadding)
                    .frame(maxWidth: .infinity)
                    .background(themeManager.currentPalette.statsContainerBackground)
                    .cornerRadius(UIConfigLayout.defaultFrameCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: UIConfigLayout.defaultFrameCornerRadius)
                            .stroke(themeManager.currentPalette.frameOutline, lineWidth: UIConfigLayout.frameOutlineWidth)
                    )
                }
                .padding(.horizontal, UIConfigLayout.contentHorizontalPadding)
                .padding(.vertical, UIConfigLayout.contentVerticalPadding)
            }
        }
        .environmentObject(themeManager) // Provide ThemeManager to the environment for subviews like IndividualStatView
    }
}

struct IndividualStatView: View {
    @EnvironmentObject var themeManager: ThemeManager // Access current theme

    let category: String
    let value: Int

    var body: some View {
        VStack(spacing: 2) { // Reduced spacing
            Text(category)
                .font(UIConfigLayout.statCategoryFont) // Uses smaller font from UIConfigLayout
                .foregroundColor(themeManager.currentPalette.statCategoryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7) // Allow more aggressive scaling if needed
            Text("\(value)")
                .font(UIConfigLayout.statValueFont) // Uses smaller font
                .foregroundColor(themeManager.currentPalette.statValueText)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: UIConfigLayout.statItemMinHeight) // Uses smaller minHeight
        .padding(UIConfigLayout.statItemInternalPadding) // Uses smaller padding
        .background(themeManager.currentPalette.statItemBackground)
        .cornerRadius(UIConfigLayout.statItemCornerRadius) // Uses smaller cornerRadius
    }
}

// MARK: - Preview
#Preview {
    CardView()
    // EnvironmentObject is automatically provided in CardView for its children,
    // and CardView itself creates its @StateObject ThemeManager for the preview.
}
