import SwiftUI

struct GlobalConfig {
    // ───────── Layout ratios ─────────
    static let topSectionHeightRatio: CGFloat = 0.50   // fraction of full height
    static let imageWidthScale:       CGFloat = 0.90   // fraction of width
    static let imageHeightMultiplier: CGFloat = 0.90   // inside top section

    // ───────── Paddings & spacing ────
    /// Extra space (in points) added to safe-area top for the title
    static let titleTopPadding:       CGFloat = -50
    /// Left/Right inset for the title
    static let titleHorizontalPadding:CGFloat = 0

    /// Horizontal inset for description + stats block
    static let statsHorizontalPadding:CGFloat = 24
    /// Spacing between grid cells in stats
    static let statsGridSpacing:      CGFloat = 16

    /// Bottom spacing (beyond safe-area) for the card-type cycler
    static let bottomCyclerPadding:   CGFloat = 12

    /// Rail width (so you can make them thicker/thinner)
    static let sideRailWidth:         CGFloat = 2

    // ───────── Fonts ─────────────────
    static let titleFont: Font = .title2.weight(.bold)

    // ───────── Corners ───────────────
    static let imageCornerRadius:     CGFloat = 12

    // ───────── Colors / opacities ────
    static let railOpacity:       CGFloat = 0.25
    static let frameFillOpacity:  CGFloat = 0.15
    static let frameStrokeOpacity:CGFloat = 0.30
}
#Preview("iPhone 15 Pro") {
    ContentView()
        .previewDevice("iPhone 15 Pro")
}
