import SwiftUI

// Make sure CardDataModels.swift is in your project and defines these:
// enum StatValue: Decodable, Hashable { ... }
// struct CardStatItem: Identifiable, Decodable, Hashable { ... var value: StatValue ... }
// struct CardContent: Identifiable, Decodable { ... }
// struct SampleCardData { ... }

struct CardView: View {
    @StateObject var themeManager = ThemeManager() // Manages theme state
    let cardContent: CardContent // MODIFIED: CardView now receives its data

    // MODIFIED: Initializer to accept the card content
    init(cardContent: CardContent = SampleCardData.vansOldSkool) { // Default sample data for easy preview/use
        self.cardContent = cardContent
    }

    var body: some View {
        ZStack {
            themeManager.currentPalette.screenBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .center, spacing: UIConfigLayout.globalVerticalSpacing) {

                    // MARK: - Title Block
                    Text(cardContent.title) // MODIFIED: Use data from cardContent
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

                    // MARK: - Image Block  (supports remote URLs now)
                    RemoteImageView(source: cardContent.localImageName)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(UIConfigLayout.imageAspectRatio, contentMode: .fit)
                        .background(themeManager.currentPalette.imagePlaceholderBackground)
                        .cornerRadius(UIConfigLayout.defaultFrameCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConfigLayout.defaultFrameCornerRadius)
                                .stroke(themeManager.currentPalette.frameOutline,
                                        lineWidth: UIConfigLayout.frameOutlineWidth)
                        )

                    // MARK: - Description Block
                    Text(cardContent.description) // MODIFIED: Use data from cardContent
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
                            ForEach(cardContent.stats) { statItem in // MODIFIED: Use data from cardContent
                                IndividualStatView(category: statItem.category, value: statItem.value) // value is now StatValue
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
    let value: StatValue // MODIFIED: Expects StatValue enum type

    var body: some View {
        VStack(spacing: 2) { // Reduced spacing
            Text(category)
                .font(UIConfigLayout.statCategoryFont) // Uses smaller font from UIConfigLayout
                .foregroundColor(themeManager.currentPalette.statCategoryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7) // Allow more aggressive scaling if needed
            Text(value.displayString) // MODIFIED: Use displayString from StatValue
                .font(UIConfigLayout.statValueFont) // Uses smaller font
                .foregroundColor(themeManager.currentPalette.statValueText)
                .lineLimit(1) // Add lineLimit for potentially longer string values
                .minimumScaleFactor(0.5) // Allow more scaling for strings
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
    // MODIFIED: Provide the required cardContent data
    CardView(cardContent: SampleCardData.vansOldSkool)
}
