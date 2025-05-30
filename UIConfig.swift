import SwiftUI

struct UIConfigRefactored { // Or your current UIConfig struct name
    // MARK: - Screen & Content Layout
    static let screenBackgroundColor: Color = Color(white: 0.2)
    static let contentHorizontalPadding: CGFloat = 15 // Padding from screen L/R edges for all content blocks
    static let contentVerticalPadding: CGFloat = 0   // Padding at the top/bottom of the scrollable content area
    static let globalVerticalSpacing: CGFloat = 18    // Spacing between major content blocks

    // MARK: - General Element Framing
    static let frameOutlineColor: Color = Color.gray.opacity(0.7) // Outline for framed elements
    static let frameOutlineWidth: CGFloat = 1.5
    static let defaultFrameCornerRadius: CGFloat = 10 // A general corner radius for framed blocks

    // MARK: - Title Block
    static let titleFont: Font = .system(size: 38, weight: .bold)
    static let titleColor: Color = .black
    static let titleFrameBackgroundColor: Color = Color.black.opacity(0.05)
    static let titleFrameInternalPadding: EdgeInsets = EdgeInsets(top: 12, leading: 10, bottom: 12, trailing: 10)
    // Uses defaultFrameCornerRadius

    // MARK: - Image Block
    static let imagePlaceholderColor: Color = Color.gray.opacity(0.25) // Inner color of the image block
    static let imageAspectRatio: CGFloat = 1.0
    // Uses defaultFrameCornerRadius for its own shape & outline

    // MARK: - Description Block
    static let descriptionFont: Font = .system(size: 15)
    static let descriptionTextColor: Color = .black
    static let descriptionBoxInternalPadding: EdgeInsets = EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    static let descriptionBoxBackgroundColor: Color = Color.white.opacity(0.6) // Inner color
    // Uses defaultFrameCornerRadius and frameOutline properties

    // MARK: - Stats Block
    static let statsContainerBackgroundColor: Color = Color.black.opacity(0.05) // Inner color for the whole stats block
    static let statsContainerInternalPadding: EdgeInsets = EdgeInsets(top: 12, leading: 10, bottom: 12, trailing: 10)
    // Uses defaultFrameCornerRadius and frameOutline properties
    // Spacing within the Stats Block (between "STATS" bar and grid)
    static let statsInternalElementsSpacing: CGFloat = 12

    // "STATS" Header Bar (This is *inside* the stats block)
    static let statsHeaderFont: Font = .system(size: 20, weight: .semibold)
    static let statsHeaderTextColor: Color = .white
    static let statsHeaderInternalPadding: EdgeInsets = EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20)
    static let statsHeaderBackgroundColor: Color = Color.orange.opacity(0.85)
    static let statsHeaderCornerRadius: CGFloat = 6

    // Stats Grid (2x2) (This is *inside* the stats block)
    static let statsGridSpacing: CGFloat = 12

    // Individual Stat Item (Category + Value)
    static let statCategoryFont: Font = .system(size: 13, weight: .medium)
    static let statCategoryColor: Color = .white
    static let statValueFont: Font = .system(size: 26, weight: .bold)
    static let statValueColor: Color = .white
    static let statItemInternalPadding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    static let statItemBackground: Color = Color.orange.opacity(0.85)
    static let statItemCornerRadius: CGFloat = 8
    static let statItemMinHeight: CGFloat = 60
}


// MARK: - Preview
#Preview {
    CardView()
}
