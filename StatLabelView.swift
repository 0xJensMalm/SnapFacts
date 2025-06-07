import SwiftUI

struct StatLabelView: View {
    let category: String
    let value: String
    let theme: CardTheme
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 0) { // No space, backgrounds will meet to form a continuous capsule look
            Text(category.uppercased())
                .font(CardView.NewCardFonts.infoBarCategory(scale: scale))
                .padding(EdgeInsets(top: 4 * scale, leading: 6 * scale, bottom: 4 * scale, trailing: 3 * scale)) // Fine-tuned padding
                .background(theme.infoLabelCategoryBackground) // Color for category part
                .foregroundColor(theme.tagText) // Using existing tagText color for now

            Text(value)
                .font(CardView.NewCardFonts.infoBarValue(scale: scale))
                .padding(EdgeInsets(top: 4 * scale, leading: 3 * scale, bottom: 4 * scale, trailing: 6 * scale)) // Fine-tuned padding
                .background(theme.infoLabelValueBackground) // Color for value part
                .foregroundColor(theme.tagText) // Using existing tagText color for now
        }
        .clipShape(Capsule()) // Clip the conjoined parts into a single capsule shape
        .frame(maxWidth: .infinity) // Allows the label to expand and helps with even distribution in parent HStack
    }
}
