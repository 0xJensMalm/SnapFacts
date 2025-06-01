import SwiftUI

// Make sure CardDataModels.swift is in your project and defines these:
// enum StatValue: Decodable, Hashable { ... }
// struct CardStatItem: Identifiable, Decodable, Hashable { ... var value: StatValue ... }
// struct CardContent: Identifiable, Decodable { ... }
// struct SampleCardData { ... }

import SwiftUI

struct CardView: View {
    @StateObject var themeManager = ThemeManager() // Manages theme state
    let cardContent: CardContent

    // State for 3D rotation (Y-axis only for flipping)
    @State private var currentYRotationAmount: Double = 0.0
    @State private var accumulatedYRotationAmount: Double = 0.0
    @State private var isFlipped: Bool = false


    // MODIFIED: Initializer to accept the card content
    init(cardContent: CardContent = SampleCardData.vansOldSkool) { // Default sample data for easy preview/use
        self.cardContent = cardContent
    }

    var body: some View {
        // Front face of the card
        let cardFrontFace = VStack(alignment: .center, spacing: UIConfigLayout.globalVerticalSpacing) {
            // MARK: - Title Block
            Text(cardContent.title)
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
            Text(cardContent.description)
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
                Text("STATS")
                    .font(UIConfigLayout.statsHeaderFont)
                    .foregroundColor(themeManager.currentPalette.statsHeaderText)
                    .padding(UIConfigLayout.statsHeaderInternalPadding)
                    .background(themeManager.currentPalette.statsHeaderBackground)
                    .cornerRadius(UIConfigLayout.statsHeaderCornerRadius)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: UIConfigLayout.statsGridSpacing),
                              GridItem(.flexible(), spacing: UIConfigLayout.statsGridSpacing)],
                    spacing: UIConfigLayout.statsGridSpacing
                ) {
                    ForEach(cardContent.stats) { statItem in
                        IndividualStatView(category: statItem.category, value: statItem.value)
                    }
                }

                HStack(spacing: UIConfigLayout.buttonsHStackSpacing) {
                    Button("Vibe") {
                        print("Vibe button tapped")
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
                        themeManager.cycleTheme()
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
                .padding(.top, 5)
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
        // cardFrontFace itself should not have a separate outer background or border;
        // these are handled by the cardStructure ZStack.

        // Card structure for flipping
        let cardStructure = ZStack {
            cardFrontFace
                .opacity(isFlipped ? 0 : 1)

            CardBackView()
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)) // Pre-rotate back view
        }
        .cornerRadius(UIConfigLayout.defaultFrameCornerRadius * 1.5) // Outer card corner radius
        .overlay(
            RoundedRectangle(cornerRadius: UIConfigLayout.defaultFrameCornerRadius * 1.5)
                .stroke(themeManager.currentPalette.frameOutline, lineWidth: UIConfigLayout.frameOutlineWidth * 1.2) // Use theme's frame outline
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4) // Slightly softer shadow for the whole card


        ZStack {
            themeManager.currentPalette.screenBackground
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                cardStructure
                    .rotation3DEffect(
                        .degrees(currentYRotationAmount + accumulatedYRotationAmount + (isFlipped ? 180 : 0)),
                        axis: (x: 0, y: 1, z: 0), // Yaw (around Y-axis)
                        perspective: 0.3
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Only allow horizontal drag to rotate around Y-axis
                                self.currentYRotationAmount = Double(value.translation.width) * 0.5
                            }
                            .onEnded { value in
                                self.accumulatedYRotationAmount += self.currentYRotationAmount
                                self.currentYRotationAmount = 0
                                // Keep accumulatedYRotationAmount within -360 to 360 to prevent excessive spinning
                                self.accumulatedYRotationAmount = self.accumulatedYRotationAmount.truncatingRemainder(dividingBy: 360)
                            }
                    )
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isFlipped.toggle()
                        // Reset drag rotation when flipping with button for a cleaner flip
                        accumulatedYRotationAmount = 0
                        currentYRotationAmount = 0
                    }
                }) {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.largeTitle)
                        .padding()
                        .foregroundColor(themeManager.currentPalette.buttonText)
                        .background(themeManager.currentPalette.buttonBackground.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(.bottom, 30)
            }
        }
        .environmentObject(themeManager)
    }
}

// Ensure SampleCardData and other model definitions are available.
// For example, in Models.swift or a dedicated CardDataModels.swift:
/*
 enum StatValue: Decodable, Hashable {
    case int(Int)
    case string(String)
    // Add other cases as needed, e.g., double(Double)

    var displayString: String {
        switch self {
        case .int(let val): return "\(val)"
        case .string(let val): return val
        }
    }
    // If you need custom Decodable conformance:
    // init(from decoder: Decoder) throws { ... }
}

struct CardStatItem: Identifiable, Decodable, Hashable {
    let id = UUID()
    var category: String
    var value: StatValue
    // Make sure CodingKeys match your JSON if it's different
}

struct CardContent: Identifiable, Decodable {
    let id: String
    var title: String
    var description: String
    var localImageName: String // Could be a URL string or local asset name
    var stats: [CardStatItem]
}

struct SampleCardData {
    static let vansOldSkool = CardContent(
        id: "1",
        title: "Vans Old Skool",
        description: "Classic skate shoe with iconic side stripe. Durable canvas and suede upper.",
        localImageName: "https://images.vans.com/is/image/Vans/VN000D3HY28-HERO?$583x583$", // Example remote URL
        stats: [
            CardStatItem(category: "Price", value: .string("$65"))
            // ... more stats ...
        ]
    )
}
*/

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
