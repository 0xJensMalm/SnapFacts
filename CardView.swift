import SwiftUI
import CoreImage.CIFilterBuiltins

// Make sure CardDataModels.swift is in your project and defines these:
// enum StatValue: Decodable, Hashable { ... }
// struct CardStatItem: Identifiable, Decodable, Hashable { ... var value: StatValue ... }
// struct CardContent: Identifiable, Decodable { ... }
// struct SampleCardData { ... }

import SwiftUI

struct CardView: View {
    @EnvironmentObject var themeManager: ThemeManager // Manages theme state
    @EnvironmentObject var snapDexManager: SnapDexManager
    let cardContent: CardContent
    let isFromSnapDex: Bool // True if viewing from SnapDex, false if newly generated
    var onDismiss: (() -> Void)? = nil // Closure to call when the view is dismissed
    @Environment(\.presentationMode) var presentationMode

    // State for 3D rotation (Y-axis only for flipping)
    @State private var currentYRotationAmount: Double = 0.0
    @State private var accumulatedYRotationAmount: Double = 0.0
    @State private var isFlipped: Bool = false
    @State private var isShareSheetPresented = false

    // Fonts based on the new design (can be moved to UIConfigLayout or defined better)
    struct NewCardFonts {
        static let title = Font.system(size: 48, weight: .bold, design: .default)
        static let infoBar = Font.system(size: 10, weight: .medium, design: .default) // Kept for reference, new labels use specific fonts
        static let tag = Font.system(size: 10, weight: .bold, design: .default)
        // New scalable fonts for Info Bar labels
        static func infoBarCategory(scale: CGFloat) -> Font {
            Font.system(size: 9 * scale, weight: .bold, design: .default)
        }
        static func infoBarValue(scale: CGFloat) -> Font {
            Font.system(size: 9 * scale, weight: .medium, design: .default)
        }
        static let idNumber = Font.system(size: 52, weight: .heavy, design: .default)
        static let idName = Font.system(size: 18, weight: .medium, design: .default)
        static let disclaimer = Font.system(size: 7, weight: .regular, design: .default)
        static let scanTo = Font.system(size: 10, weight: .bold, design: .default)
    }


    private func generateQRCode(from string: String) -> Image? {
        let context = CIContext()
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // Correction level

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10) // Scale for clarity
            let scaledCIImage = outputImage.transformed(by: transform)
            if let cgimg = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) {
                let uiImage = UIImage(cgImage: cgimg)
                return Image(uiImage: uiImage)
                    .interpolation(.none) // Keep it sharp
            }
        }
        return nil
    }

    // MODIFIED: Initializer to accept card content, SnapDex status, and an onDismiss closure
    init(cardContent: CardContent, isFromSnapDex: Bool, onDismiss: (() -> Void)? = nil) { 
        self.cardContent = cardContent
        self.isFromSnapDex = isFromSnapDex
        self.onDismiss = onDismiss
        // The displayId should be part of CardContent, set when the card is created.
        // No need to manage uniqueCardId state here if cardContent.displayId is reliable.
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.85
            let baseCardWidth: CGFloat = 320
            let baseCardHeight: CGFloat = 600
            let cardAspectRatio = baseCardHeight / baseCardWidth
            let cardHeight = cardWidth * cardAspectRatio
            let scale = cardWidth / baseCardWidth

            // Inner frame line properties
            let innerFramePadding = 5 * scale // Padding from the card edge to the frame line
            let innerFrameLineWidth = 1 * scale // Thickness of the frame line
            let qrCodeSectionSize = 75 * scale // New size for QR code section (width & height)

            // NEW Card Front Face Design - Refactored into 5 Containers
            let cardFrontFace = VStack(alignment: .center, spacing: 12 * scale) { // Main VStask for the 5 containers

                // --- Container 1: Top Header (Logo + Title/ID) ---
                HStack(alignment: .center, spacing: 10 * scale) {
                    Image("snapFacts")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100 * scale)

                    VStack(alignment: .leading, spacing: 4 * scale) { // Increased spacing
                        Text(String(format: "%03d", cardContent.displayId))
                            .font(NewCardFonts.idNumber.weight(.medium))
                            .foregroundColor(themeManager.currentTheme.idNumberText)
                        Text(cardContent.title.uppercased())
                            .font(NewCardFonts.idName.weight(.semibold))
                            .foregroundColor(themeManager.currentTheme.idNameText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) // Changed alignment
                    .padding(.leading, 15 * scale) // Added padding to create a gap
                }
                .padding(.top, 10 * scale) // Padding for content within this container

                // --- Container 2: Main Image ---
                ZStack {
                    RoundedRectangle(cornerRadius: 12 * scale)
                        .fill(themeManager.currentTheme.imageFrameBackground)
                    
                    RemoteImageView(source: cardContent.localImageName)
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200 * scale)
                        .clipShape(RoundedRectangle(cornerRadius: 10 * scale))
                        .padding(4 * scale)
                }
                .frame(height: 225 * scale) // Overall height for the image container

                // --- Container 3: Description Text ---
                Text(cardContent.description)
                    .font(Font.system(size: 12 * scale, weight: .regular))
                    .foregroundColor(themeManager.currentTheme.idNameText)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 10 * scale) // Horizontal padding for the text
                    .padding(.vertical, 5 * scale)   // Vertical padding around the text
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                // --- Container 4: Stats Bar ---
                HStack(spacing: 5 * scale) {
                    ForEach(cardContent.stats) { statItem in
                        StatLabelView(category: statItem.category, value: statItem.value.displayString, theme: themeManager.currentTheme, scale: scale)
                    }
                }
                .padding(.horizontal, 10 * scale) // Padding for content within the stats bar background
                .padding(.vertical, 6 * scale)   // Padding for content within the stats bar background
                .background(themeManager.currentTheme.infoBarBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12 * scale))

                // --- Container 5: Bottom Section (FP + QR Code) ---
                HStack(alignment: .center, spacing: 10 * scale) {
                    // Left Column (FP Placeholder)
                    VStack(alignment: .center, spacing: 4 * scale) {
                        RoundedRectangle(cornerRadius: 8 * scale)
                            .fill(themeManager.currentTheme.fingerprintBackground)
                            .frame(width: 60 * scale, height: 60 * scale)
                            .overlay(
                                Text("FP")
                                    .font(.system(size: 18 * scale, weight: .bold))
                                    .foregroundColor(themeManager.currentTheme.fingerprintSymbol)
                            )
                            .onTapGesture {
                                themeManager.cycleTheme()
                            }
                    }
                    .padding(10 * scale) // Internal padding for the FP container background
                    .frame(maxWidth: .infinity, idealHeight: qrCodeSectionSize, maxHeight: qrCodeSectionSize)
                    .background(themeManager.currentTheme.bottomContainerBackground)
                    .cornerRadius(8 * scale)

                    // Right Column (QR Code and Vertical Text)
                    HStack(spacing: 5 * scale) {
                        Text("SCAN TO")
                            .font(NewCardFonts.scanTo)
                            .foregroundColor(themeManager.currentTheme.scanToText)
                            .rotationEffect(.degrees(-90))
                            .fixedSize()
                            .frame(width: 20 * scale, height: qrCodeSectionSize)

                        RoundedRectangle(cornerRadius: 4 * scale)
                            .fill(themeManager.currentTheme.qrCodePlaceholderBackground)
                            .frame(width: qrCodeSectionSize, height: qrCodeSectionSize)
                            .overlay(
                                Group {
                                    if let qrImage = generateQRCode(from: cardContent.id) {
                                        qrImage
                                            .resizable()
                                            .scaledToFit()
                                            .padding(8 * scale)
                                    } else {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .padding(8 * scale)
                                            .foregroundColor(.red)
                                    }
                                }
                            )

                        Text("TRANSFER")
                            .font(NewCardFonts.scanTo)
                            .foregroundColor(themeManager.currentTheme.scanToText)
                            .rotationEffect(.degrees(-90))
                            .fixedSize()
                            .frame(width: 20 * scale, height: qrCodeSectionSize)
                    }
                    .frame(height: qrCodeSectionSize) // Ensure QR section respects the height
                }
                // The main VStack's spacing and the overall cardFrontFace padding will handle bottom spacing before the Spacer.
                
                Spacer() // Pushes all content to the top if card is taller
            }
            .padding(EdgeInsets(top: 10 * scale, leading: 8 * scale, bottom: 10 * scale, trailing: 8 * scale)) // Apply consistent padding to cardFrontFace
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
            .background(themeManager.currentTheme.cardBackground) // Apply background to the sized ZStack
            .cornerRadius(UIConfigLayout.defaultFrameCornerRadius * 1.5) // Then apply corner radius
            .overlay( // Static white outline on the card's edge
                RoundedRectangle(cornerRadius: UIConfigLayout.defaultFrameCornerRadius * 1.5)
                    .strokeBorder(Color.white, lineWidth: 1.5 * scale) // White outline, slightly thicker
            )
            .overlay( // Themed inner frame line, inset from the white outline
                RoundedRectangle(cornerRadius: UIConfigLayout.defaultFrameCornerRadius * 1.5)
                    .strokeBorder(themeManager.currentTheme.innerFrameLine, lineWidth: innerFrameLineWidth)
                    .padding(innerFramePadding) // This padding ensures it's inside the white outline
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)


            // This ZStack is for the overall screen layout, placing cardStructure and the unified button row
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    cardStructure
                        .rotation3DEffect(
                            .degrees(currentYRotationAmount + accumulatedYRotationAmount + (isFlipped ? 180 : 0)),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.3
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    self.currentYRotationAmount = Double(value.translation.width) * 0.5
                                }
                                .onEnded { value in
                                    self.accumulatedYRotationAmount += self.currentYRotationAmount
                                    self.currentYRotationAmount = 0
                                    self.accumulatedYRotationAmount = self.accumulatedYRotationAmount.truncatingRemainder(dividingBy: 360)
                                }
                        )
                    Spacer()

                    // --- NEW UNIFIED BUTTON ROW ---
                    HStack(spacing: 30 * scale) {
                        // DISCARD BUTTON (X) - shows only when newly generated
                        if !isFromSnapDex {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 24 * scale, weight: .bold))
                                    .frame(width: 50 * scale, height: 50 * scale)
                                    .foregroundColor(.white)
                                    .background(Color.red.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: max(2, 5 * scale))
                            }
                        }

                        // FLIP BUTTON - always shows
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                isFlipped.toggle()
                                accumulatedYRotationAmount = 0
                                currentYRotationAmount = 0
                            }
                        }) {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.system(size: 32 * scale, weight: .bold))
                                .frame(width: 60 * scale, height: 60 * scale)
                                .foregroundColor(themeManager.currentTheme.tagText)
                                .background(themeManager.currentTheme.tagBackground.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: max(2, 5 * scale))
                        }

                        // KEEP (✓) or RELEASE (trash) BUTTON
                        if isFromSnapDex {
                            // RELEASE BUTTON
                            Button(action: {
                                snapDexManager.releaseCard(cardContent)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 24 * scale, weight: .bold))
                                    .frame(width: 50 * scale, height: 50 * scale)
                                    .foregroundColor(.white)
                                    .background(Color.red.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: max(2, 5 * scale))
                            }
                        } else {
                            // KEEP BUTTON
                            Button(action: {
                                snapDexManager.addCard(cardContent)
                            }) {
                                Image(systemName: snapDexManager.isCardCollected(cardContent) ? "checkmark.circle.fill" : "checkmark")
                                    .font(.system(size: 24 * scale, weight: .bold))
                                    .frame(width: 50 * scale, height: 50 * scale)
                                    .foregroundColor(.white)
                                    .background(snapDexManager.isCardCollected(cardContent) ? Color.green.opacity(0.5) : Color.green.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: max(2, 5 * scale))
                            }
                            .disabled(snapDexManager.isCardCollected(cardContent))
                        }
                    }
                    .padding(.bottom, geometry.size.height * 0.05)
                }
            }
        }
        // .environmentObject(themeManager) // Already provided by parent or App
        .onDisappear {
            // Call the onDismiss closure if it's set
            // This is useful for cleanup when CardView is popped, especially for newly generated cards.
            onDismiss?()
        }
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
                .foregroundColor(themeManager.currentTheme.idNameText)
                .lineLimit(1)
                .minimumScaleFactor(0.7) // Allow more aggressive scaling if needed
            Text(value.displayString) // MODIFIED: Use displayString from StatValue
                .font(UIConfigLayout.statValueFont) // Uses smaller font
                .foregroundColor(themeManager.currentTheme.idNumberText)
                .lineLimit(1) // Add lineLimit for potentially longer string values
                .minimumScaleFactor(0.5) // Allow more scaling for strings
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: UIConfigLayout.statItemMinHeight) // Uses smaller minHeight
        .padding(UIConfigLayout.statItemInternalPadding) // Uses smaller padding
        .background(themeManager.currentTheme.imageFrameBackground)
        .cornerRadius(UIConfigLayout.statItemCornerRadius) // Uses smaller cornerRadius
    }
}

// MARK: - Preview
#Preview {
    // MODIFIED: Provide the required cardContent data, isFromSnapDex, and environment objects
    CardView(cardContent: SampleCardData.vansOldSkool, isFromSnapDex: false)
        .environmentObject(SnapDexManager())
        .environmentObject(ThemeManager())
}
