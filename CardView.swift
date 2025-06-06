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


    // Colors based on the new design (can be moved to ThemeManager/UIColors later)
    struct NewCardColors {
        static let cardBackground = Color(red: 0.96, green: 0.94, blue: 0.90) // Cream/Beige
        static let titleText = Color(red: 0.4, green: 0.49, blue: 0.5) // Muted dark teal/grey
        static let frameBorder = Color(red: 0.4, green: 0.49, blue: 0.5)
        static let imageFrameBackground = Color(red: 0.87, green: 0.91, blue: 0.93) // Pale sky blue/light grey
        static let infoBarBackground = Color(red: 0.4, green: 0.49, blue: 0.5)
        static let infoBarText = Color(red: 0.96, green: 0.94, blue: 0.90)
        static let tagBackground = Color(red: 0.98, green: 0.76, blue: 0.45) // Yellow/Ochre
        static let tagText = Color(red: 0.2, green: 0.2, blue: 0.2) // Dark grey/black
        static let idNumberText = Color(red: 0.2, green: 0.2, blue: 0.2)
        static let idNameText = Color(red: 0.25, green: 0.25, blue: 0.25)
        static let disclaimerText = Color(red: 0.6, green: 0.6, blue: 0.6) // Light grey
        static let fingerprintBackground = Color(red: 0.8, green: 0.85, blue: 0.86)
        static let qrCodePlaceholder = Color.gray
        static let scanToText = Color(red: 0.2, green: 0.2, blue: 0.2)
        static let innerFrameLine: Color = Color.gray.opacity(0.5) // For the new inner frame line
    }

    // Fonts based on the new design (can be moved to UIConfigLayout or defined better)
    struct NewCardFonts {
        static let title = Font.system(size: 48, weight: .bold, design: .default)
        static let infoBar = Font.system(size: 10, weight: .medium, design: .default)
        static let tag = Font.system(size: 10, weight: .bold, design: .default)
        static let idNumber = Font.system(size: 40, weight: .heavy, design: .default)
        static let idName = Font.system(size: 14, weight: .medium, design: .default)
        static let disclaimer = Font.system(size: 7, weight: .regular, design: .default)
        static let scanTo = Font.system(size: 10, weight: .bold, design: .default)
    }


    // MODIFIED: Initializer to accept the card content
    init(cardContent: CardContent = SampleCardData.vansOldSkool) { // Default sample data for easy preview/use
        self.cardContent = cardContent
    }

    // Private helper view for styling info tags
    private struct InfoTagView: View {
        let text: String
        let scale: CGFloat

        var body: some View {
            Text(text)
                .font(NewCardFonts.tag)
                .foregroundColor(NewCardColors.tagText)
                .padding(.horizontal, 10 * scale)
                .padding(.vertical, 4 * scale)
                .background(NewCardColors.tagBackground)
                .clipShape(Capsule())
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.8
            let baseCardWidth: CGFloat = 320
            let baseCardHeight: CGFloat = 500
            let cardAspectRatio = baseCardHeight / baseCardWidth
            let cardHeight = cardWidth * cardAspectRatio
            let scale = cardWidth / baseCardWidth

            // Inner frame line properties
            let innerFramePadding = 5 * scale // Padding from the card edge to the frame line
            let innerFrameLineWidth = 1 * scale // Thickness of the frame line
            let qrCodeSectionSize = 75 * scale // New size for QR code section (width & height)

            // NEW Card Front Face Design
            let cardFrontFace = VStack(alignment: .center, spacing: 0) {
                // 1. Top Title Section
                Text(cardContent.title.uppercased())
                    .font(NewCardFonts.title) // Font size not scaled for now
                    .foregroundColor(NewCardColors.titleText)
                    .padding(.top, 20 * scale)
                    .padding(.bottom, 10 * scale)

                // 2. Main Image Section
                ZStack {
                    RoundedRectangle(cornerRadius: 12 * scale)
                        .fill(NewCardColors.imageFrameBackground)
                    
                    RemoteImageView(source: cardContent.localImageName)
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200 * scale)
                        .clipShape(RoundedRectangle(cornerRadius: 10 * scale))
                        .padding(4 * scale)
                }
                // Horizontal padding removed, now controlled by cardFrontFace
                .frame(height: 210 * scale) // Total height for the image section including padding
                .padding(.bottom, 15 * scale)

                // 3. Info Bar
                HStack(spacing: 8 * scale) {
                    InfoTagView(text: "VAL 1", scale: scale)
                    InfoTagView(text: "VAL 2", scale: scale)
                    InfoTagView(text: "VAL 3", scale: scale)
                    InfoTagView(text: "VAL 4", scale: scale)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4 * scale)
                .padding(.vertical, 8 * scale)
                .background(NewCardColors.infoBarBackground)
                .cornerRadius(8 * scale)
                // Horizontal padding removed, now controlled by cardFrontFace
                .padding(.bottom, 15 * scale)

                // 4. Bottom Section
                HStack(alignment: .center, spacing: 10 * scale) { // Align items center vertically
                    // Left Column (New Container for FP, ID, Name)
                    VStack(alignment: .leading, spacing: 4 * scale) {
                        HStack(alignment: .bottom, spacing: 8 * scale) {
                            RoundedRectangle(cornerRadius: 6 * scale)
                                .fill(NewCardColors.fingerprintBackground)
                                .frame(width: 50 * scale, height: 50 * scale)
                                .overlay(
                                    Text("FP")
                                        .font(.system(size: max(6, 10 * scale)))
                                        .foregroundColor(.gray)
                                )
                            VStack(alignment: .leading, spacing: 0) {
                                Text("005") // Placeholder ID Number
                                    .font(NewCardFonts.idNumber)
                                    .foregroundColor(NewCardColors.idNumberText)
                                Text("\"\(cardContent.title.uppercased())_ID\"") // Placeholder ID Name
                                    .font(NewCardFonts.idName)
                                    .foregroundColor(NewCardColors.idNameText)
                            }
                        }
                        // Disclaimer and Spacer removed
                    }
                    .padding(10 * scale) // Internal padding for the new container
                    .frame(maxWidth: .infinity, idealHeight: qrCodeSectionSize, maxHeight: qrCodeSectionSize) // Span width, match QR height
                    .background(NewCardColors.imageFrameBackground) // Light background for the container
                    .cornerRadius(8 * scale)

                    // Right Column (QR Code and Vertical Text)
                    HStack(spacing: 5 * scale) {
                        Text("SCOAN TO")
                            .font(NewCardFonts.scanTo)
                            .foregroundColor(NewCardColors.scanToText)
                            .rotationEffect(.degrees(-90))
                            .fixedSize()
                            .frame(width: 20 * scale, height: qrCodeSectionSize) // Adjusted width, match QR height

                        RoundedRectangle(cornerRadius: 4 * scale)
                            .fill(NewCardColors.qrCodePlaceholder)
                            .frame(width: qrCodeSectionSize, height: qrCodeSectionSize) // Use new QR code size
                            .overlay(
                                Image(systemName: "qrcode")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(8 * scale) // Slightly more padding for larger QR
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(height: qrCodeSectionSize) // Ensure this HStack also respects the height
                }
                .padding(.bottom, 20 * scale)
                
                Spacer() // Pushes all content to the top if card is taller
            }
            .padding(EdgeInsets(top: 20 * scale, leading: 15 * scale, bottom: 20 * scale, trailing: 15 * scale)) // Apply consistent padding to cardFrontFace
            .frame(maxWidth: .infinity, maxHeight: .infinity) // cardFrontFace fills its parent (cardStructure)

            // Card structure for flipping
            let cardStructure = ZStack {
                cardFrontFace
                    .opacity(isFlipped ? 0 : 1)

                CardBackView() // Assuming CardBackView also adapts or is fine with new size
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)) // Pre-rotate back view
            }
            .frame(width: cardWidth, height: cardHeight)
            .background(NewCardColors.cardBackground) // Apply background to the sized ZStack
            .cornerRadius(UIConfigLayout.defaultFrameCornerRadius * 1.5) // Then apply corner radius
            .overlay(
                RoundedRectangle(cornerRadius: UIConfigLayout.defaultFrameCornerRadius * 1.5)
                    .strokeBorder(NewCardColors.innerFrameLine, lineWidth: innerFrameLineWidth)
                    .padding(innerFramePadding)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)


            // This ZStack is for the overall screen layout, placing cardStructure and button
            ZStack {
                Color.gray.opacity(0.3) // Example: A neutral darkish background
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    cardStructure // This is the dynamically sized, backgrounded, and styled card
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
                            .font(.largeTitle) // Consider scaling font or using relative size
                            .padding() // Consider scaling padding
                            .foregroundColor(themeManager.currentPalette.buttonText)
                            .background(themeManager.currentPalette.buttonBackground.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: max(2,5 * scale)) // Consider scaling shadow
                    }
                    .padding(.bottom, geometry.size.height * 0.05) // Scaled bottom padding for button
                }
            }
            // The ZStack above will fill the GeometryReader by default
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
