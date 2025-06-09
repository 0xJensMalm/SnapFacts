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
        static let idNumber = Font.system(size: 40, weight: .heavy, design: .default)
        static let idName = Font.system(size: 14, weight: .medium, design: .default)
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
            let cardWidth = geometry.size.width * 0.95
            let baseCardWidth: CGFloat = 320
            let baseCardHeight: CGFloat = 600
            let cardAspectRatio = baseCardHeight / baseCardWidth
            let cardHeight = cardWidth * cardAspectRatio
            let scale = cardWidth / baseCardWidth

            // Inner frame line properties
            let innerFramePadding = 5 * scale // Padding from the card edge to the frame line
            let innerFrameLineWidth = 1 * scale // Thickness of the frame line
            let qrCodeSectionSize = 75 * scale // New size for QR code section (width & height)

            // NEW Card Front Face Design
            let cardFrontFace = VStack(alignment: .center, spacing: 0) {
                // 1. Top Header Section (Logo and Title/ID)
                HStack(alignment: .center, spacing: 10 * scale) { // Align items vertically centered
                    Image("snapFacts")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120 * scale) // User updated logo height to 120 * scale

                    // This VStack contains the ID and Title. It's pushed to the right.
                    VStack(alignment: .leading, spacing: 2 * scale) { // Internal text alignment is leading
                        Text(String(format: "%03d", cardContent.displayId)) // Display card's persistent ID
                            .font(NewCardFonts.idNumber.weight(.medium))
                            .foregroundColor(themeManager.currentTheme.idNumberText)
                        Text(cardContent.title.uppercased())
                            .font(NewCardFonts.idName.weight(.semibold))
                            .foregroundColor(themeManager.currentTheme.idNameText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true) // Allows text to wrap
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing) // Pushes this VStack to the trailing edge of the HStack
                }
                .padding(.top, 15 * scale) // Vertical padding for the header section
                .padding(.bottom, 0 * scale) // MOVED IMAGE UP: No padding after header, before main image

                // 2. Main Image Section
                ZStack {
                    RoundedRectangle(cornerRadius: 12 * scale)
                        .fill(themeManager.currentTheme.imageFrameBackground)
                    
                    RemoteImageView(source: cardContent.localImageName)
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200 * scale)
                        .clipShape(RoundedRectangle(cornerRadius: 10 * scale))
                        .padding(4 * scale)
                }
                // Horizontal padding removed, now controlled by cardFrontFace
                .frame(height: 225 * scale) // Image frame height (can be increased if needed due to more space)
                .padding(.bottom, 5 * scale) // Padding after image

                // NEW: Description Text Section
                Text(cardContent.description)
                    .font(Font.system(size: 12 * scale, weight: .regular))
                    .foregroundColor(themeManager.currentTheme.idNameText) // Using a common text color, adjust if needed
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 10 * scale) // Horizontal padding to align with other content
                    .padding(.vertical, 5 * scale) // Vertical padding around the description
                    .frame(maxWidth: .infinity, alignment: .leading) // Ensure it takes available width and aligns leading
                    .fixedSize(horizontal: false, vertical: true) // Allow text to wrap

                // 3. Info Bar - Redesigned with StatLabelView
                HStack(spacing: 5 * scale) { // Spacing between StatLabelViews
                    ForEach(cardContent.stats) { statItem in
                        StatLabelView(category: statItem.category, value: statItem.value.displayString, theme: themeManager.currentTheme, scale: scale)
                    }
                }
                .padding(.horizontal, 10 * scale) // Overall horizontal padding for the info bar content
                .padding(.vertical, 6 * scale)   // Vertical padding around the StatLabelViews, inside the info bar background
                .background(themeManager.currentTheme.infoBarBackground) // Background for the entire info bar area
                .clipShape(RoundedRectangle(cornerRadius: 12 * scale))
                .padding(.bottom, 20 * scale) // Increased padding between Info Bar and Bottom Section

                // 4. Bottom Section
                HStack(alignment: .center, spacing: 10 * scale) { // Align items center vertically
                    // Left Column (New Container for FP - Centered)
                    VStack(alignment: .center, spacing: 4 * scale) { // Changed to .center for FP box
                        // FP Box - now directly in the VStack, will be centered
                        RoundedRectangle(cornerRadius: 8 * scale) // Slightly larger corner radius
                            .fill(themeManager.currentTheme.fingerprintBackground)
                            .frame(width: 60 * scale, height: 60 * scale) // Slightly larger FP box
                            .overlay(
                                Text("FP")
                                    .font(.system(size: 18 * scale, weight: .bold)) // Larger, bolder "FP" text
                                    .foregroundColor(themeManager.currentTheme.fingerprintSymbol)
                            )
                            .onTapGesture {
                                themeManager.cycleTheme()
                            }
                    }
                    .padding(10 * scale) // Internal padding for the container
                    .frame(maxWidth: .infinity, idealHeight: qrCodeSectionSize, maxHeight: qrCodeSectionSize) // Span width, match QR height
                    .background(themeManager.currentTheme.bottomContainerBackground)
                    .cornerRadius(8 * scale)

                    // Right Column (QR Code and Vertical Text)
                    HStack(spacing: 5 * scale) {
                        Text("SCAN TO")
                            .font(NewCardFonts.scanTo)
                            .foregroundColor(themeManager.currentTheme.scanToText)
                            .rotationEffect(.degrees(-90))
                            .fixedSize()
                            .frame(width: 20 * scale, height: qrCodeSectionSize) // Adjusted width, match QR height

                        RoundedRectangle(cornerRadius: 4 * scale)
                            .fill(themeManager.currentTheme.qrCodePlaceholderBackground)
                            .frame(width: qrCodeSectionSize, height: qrCodeSectionSize) // Use new QR code size
                            .overlay(
                                Group {
                                    if let qrImage = generateQRCode(from: cardContent.id) {
                                        qrImage
                                            .resizable()
                                            .scaledToFit()
                                            .padding(8 * scale) // Keep padding for consistency
                                    } else {
                                        // Fallback if QR generation fails
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .padding(8 * scale)
                                            .foregroundColor(.red) // Make fallback noticeable
                                    }
                                }
                            )

                        Text("TRANSFER")
                            .font(NewCardFonts.scanTo) // Use the same font as SCAN TO
                            .foregroundColor(themeManager.currentTheme.scanToText) // Use the same color
                            .rotationEffect(.degrees(-90)) // Same rotation
                            .fixedSize()
                            .frame(width: 20 * scale, height: qrCodeSectionSize) // Same frame setup
                    }
                    .frame(height: qrCodeSectionSize) // Ensure this HStack also respects the height
                }
                .padding(.bottom, 30 * scale) // Increased bottom padding for more space
                
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


            // This ZStack is for the overall screen layout, placing cardStructure and button
            ZStack {
                Color.black // Set background to black as requested
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
                    // OLD FLIP BUTTON REMOVED FROM HERE
                    Spacer() // This Spacer pushes the button bar to the bottom

                    // NEW Buttons HStack - Now correctly placed within the main VStack
                    HStack(spacing: 20 * scale) { // Adjust spacing as needed
                // Left Button (Discard or Release)
                if isFromSnapDex {
                    Button(action: {
                        snapDexManager.releaseCard(cardContent)
                        presentationMode.wrappedValue.dismiss() // Dismiss after releasing
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24 * scale, weight: .bold))
                            .padding(15 * scale)
                            .foregroundColor(.white)
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 3 * scale, x: 0, y: 2 * scale)
                    }
                } else {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24 * scale, weight: .bold))
                            .padding(15 * scale)
                            .foregroundColor(.white)
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 3 * scale, x: 0, y: 2 * scale)
                    }
                }

                Spacer()

                // Center Button (Flip)
                Button(action: {
                    withAnimation(.spring()) {
                        isFlipped.toggle()
                        accumulatedYRotationAmount = 0
                        currentYRotationAmount = 0
                    }
                }) {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 30 * scale, weight: .medium)) // Adjusted size slightly
                        .padding(12 * scale) // Adjusted padding slightly
                        .foregroundColor(themeManager.currentTheme.tagText)
                        .background(themeManager.currentTheme.tagBackground.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.4), radius: max(2,4 * scale), x: 0, y: max(1,2 * scale)) // Adjusted shadow
                }

                Spacer()

                // Right Button (Keep - only if not from SnapDex)
                if !isFromSnapDex {
                    Button(action: {
                        snapDexManager.addCard(cardContent)
                        presentationMode.wrappedValue.dismiss() // Dismiss after collecting
                    }) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 24 * scale, weight: .bold))
                            .padding(15 * scale)
                            .foregroundColor(.white)
                            .background(snapDexManager.isCardCollected(cardContent) ? Color.green.opacity(0.7) : Color.green)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 3 * scale, x: 0, y: 2 * scale)
                    }
                    .disabled(snapDexManager.isCardCollected(cardContent))
                } else {
                    // Placeholder to maintain balance if needed, or rely on Spacers
                    // For true centering of Flip when Keep is not present, ensure this side has equal 'flex'
                    // An empty Spacer or a clear rectangle can work if Spacers alone don't center perfectly.
                    // For now, let the two Spacers handle it.
                    Spacer().frame(width: (24 * scale) + (30 * scale)) // Approximate width of a button to help balance if only 2 buttons active
                }
            }
            .frame(maxWidth: .infinity) // Ensure HStack expands to allow Spacers to work
            .padding(.horizontal, 20 * scale) // Horizontal padding for the button bar
            .padding(.bottom, geometry.size.height * 0.03) // Bottom padding for the button bar
                } // This closes the main VStack
            } // This closes the ZStack with the black background
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
