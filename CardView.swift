import SwiftUI

// Sample Data Structure (ensure this matches your actual data model)
struct CardStatItem: Identifiable {
    let id = UUID()
    var category: String
    var value: Int
}

struct CardView: View { // Assuming you renamed it back to CardView
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
            // Screen Background
            UIConfigRefactored.screenBackgroundColor
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .center, spacing: UIConfigRefactored.globalVerticalSpacing) {

                    // MARK: - Title Block (Framed with Outline)
                    Text(cardTitle)
                        .font(UIConfigRefactored.titleFont)
                        .foregroundColor(UIConfigRefactored.titleColor)
                        .multilineTextAlignment(.center)
                        .padding(UIConfigRefactored.titleFrameInternalPadding)
                        .frame(maxWidth: .infinity) // Key for width alignment
                        .background(UIConfigRefactored.titleFrameBackgroundColor)
                        .cornerRadius(UIConfigRefactored.defaultFrameCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConfigRefactored.defaultFrameCornerRadius)
                                .stroke(UIConfigRefactored.frameOutlineColor, lineWidth: UIConfigRefactored.frameOutlineWidth)
                        )

                    // MARK: - Image Block (Framed with Outline)
                    Rectangle() // Image Placeholder
                        .fill(UIConfigRefactored.imagePlaceholderColor) // Inner color
                        .aspectRatio(UIConfigRefactored.imageAspectRatio, contentMode: .fit)
                        .frame(maxWidth: .infinity) // Key for width alignment
                        .cornerRadius(UIConfigRefactored.defaultFrameCornerRadius) // Shape
                        .overlay( // Icon on top
                            Image(systemName: cardImagePlaceholderIconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(Color.white.opacity(0.7))
                        )
                        .overlay( // Outline for the image block
                            RoundedRectangle(cornerRadius: UIConfigRefactored.defaultFrameCornerRadius)
                                .stroke(UIConfigRefactored.frameOutlineColor, lineWidth: UIConfigRefactored.frameOutlineWidth)
                        )


                    // MARK: - Description Block (Framed with Outline)
                    Text(cardDescription)
                        .font(UIConfigRefactored.descriptionFont)
                        .foregroundColor(UIConfigRefactored.descriptionTextColor)
                        .multilineTextAlignment(.center)
                        .padding(UIConfigRefactored.descriptionBoxInternalPadding)
                        .frame(maxWidth: .infinity) // Key for width alignment
                        .background(UIConfigRefactored.descriptionBoxBackgroundColor)
                        .cornerRadius(UIConfigRefactored.defaultFrameCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConfigRefactored.defaultFrameCornerRadius)
                                .stroke(UIConfigRefactored.frameOutlineColor, lineWidth: UIConfigRefactored.frameOutlineWidth)
                        )

                    // MARK: - Stats Block (Framed with Outline)
                    VStack(spacing: UIConfigRefactored.statsInternalElementsSpacing) {
                        // "STATS" Header Bar
                        Text("STATS")
                            .font(UIConfigRefactored.statsHeaderFont)
                            .foregroundColor(UIConfigRefactored.statsHeaderTextColor)
                            .padding(UIConfigRefactored.statsHeaderInternalPadding)
                            .background(UIConfigRefactored.statsHeaderBackgroundColor)
                            .cornerRadius(UIConfigRefactored.statsHeaderCornerRadius)

                        // 2x2 Grid for Stats
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: UIConfigRefactored.statsGridSpacing),
                                      GridItem(.flexible(), spacing: UIConfigRefactored.statsGridSpacing)],
                            spacing: UIConfigRefactored.statsGridSpacing
                        ) {
                            ForEach(stats) { statItem in
                                IndividualStatView(category: statItem.category, value: statItem.value)
                            }
                        }
                    }
                    .padding(UIConfigRefactored.statsContainerInternalPadding)
                    .frame(maxWidth: .infinity) // Key for width alignment
                    .background(UIConfigRefactored.statsContainerBackgroundColor) // Inner color
                    .cornerRadius(UIConfigRefactored.defaultFrameCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: UIConfigRefactored.defaultFrameCornerRadius)
                            .stroke(UIConfigRefactored.frameOutlineColor, lineWidth: UIConfigRefactored.frameOutlineWidth)
                    )
                }
                .padding(.horizontal, UIConfigRefactored.contentHorizontalPadding) // L/R padding for all content
                .padding(.vertical, UIConfigRefactored.contentVerticalPadding)   // Top/Bottom padding for scroll content
            }
        }
    }
}

// MARK: - Individual Stat Item View (Unchanged, but uses UIConfig)
struct IndividualStatView: View {
    let category: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(category)
                .font(UIConfigRefactored.statCategoryFont)
                .foregroundColor(UIConfigRefactored.statCategoryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text("\(value)")
                .font(UIConfigRefactored.statValueFont)
                .foregroundColor(UIConfigRefactored.statValueColor)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: UIConfigRefactored.statItemMinHeight)
        .padding(UIConfigRefactored.statItemInternalPadding)
        .background(UIConfigRefactored.statItemBackground)
        .cornerRadius(UIConfigRefactored.statItemCornerRadius)
    }
}

// MARK: - Preview
#Preview {
    CardView()
}
