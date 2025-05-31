import SwiftUI

struct UIConfigLayout {
    
    // MARK: - Camera View
    static let appHeaderFont: Font = .system(size: 22, weight: .bold) // Font for "Snap Facts"
    static let appHeaderPadding: EdgeInsets = EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20) // Internal padding for the header bar

    // For the Bottom Controls Container
    static let controlsContainerPadding: EdgeInsets = EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15)// Internal padding for the button container
    static let controlsContainerSpacing: CGFloat = 15 // Spacing for items within the controls container (e.g., New Picture button and main button)

    
    // MARK: - Screen & Content Layout
    static let contentHorizontalPadding: CGFloat = 15
    static let contentVerticalPadding: CGFloat = 20
    static let globalVerticalSpacing: CGFloat = 18

    // MARK: - General Element Framing
    static let frameOutlineWidth: CGFloat = 1.5
    static let defaultFrameCornerRadius: CGFloat = 10

    // MARK: - Title Block
    static let titleFont: Font = .system(size: 36, weight: .bold) // Slightly smaller for balance
    static let titleFrameInternalPadding: EdgeInsets = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

    // MARK: - Image Block
    static let imageAspectRatio: CGFloat = 1.0 // Square

    // MARK: - Description Block
    static let descriptionFont: Font = .system(size: 14) // Slightly smaller
    static let descriptionBoxInternalPadding: EdgeInsets = EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)

    // MARK: - Stats Block
    static let statsContainerInternalPadding: EdgeInsets = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
    static let statsInternalElementsSpacing: CGFloat = 10 // Spacing between STATS bar, grid, and new buttons

    // "STATS" Header Bar
    static let statsHeaderFont: Font = .system(size: 18, weight: .semibold) // Slightly smaller
    static let statsHeaderInternalPadding: EdgeInsets = EdgeInsets(top: 5, leading: 18, bottom: 5, trailing: 18)
    static let statsHeaderCornerRadius: CGFloat = 6

    // Stats Grid
    static let statsGridSpacing: CGFloat = 8 // Reduced for smaller items

    // Individual Stat Item (Made Smaller)
    static let statCategoryFont: Font = .system(size: 10, weight: .semibold)
    static let statValueFont: Font = .system(size: 18, weight: .bold)
    static let statItemInternalPadding: EdgeInsets = EdgeInsets(top: 4, leading: 5, bottom: 4, trailing: 5)
    static let statItemCornerRadius: CGFloat = 5
    static let statItemMinHeight: CGFloat = 40 // Significantly reduced

    // MARK: - New Buttons in Stats Block
    static let actionButtonFont: Font = .system(size: 13, weight: .medium)
    static let actionButtonPadding: EdgeInsets = EdgeInsets(top: 7, leading: 12, bottom: 7, trailing: 12)
    static let actionButtonCornerRadius: CGFloat = 8
    static let actionButtonOutlineWidth: CGFloat = 1.0
    static let buttonsHStackSpacing: CGFloat = 10
}
