import SwiftUI

// Helper Shape for specific rounded corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct StatLabelView: View {
    let category: String
    let value: String
    let theme: CardTheme
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // Category on top of value
            Text(category.uppercased())
                .font(CardView.NewCardFonts.infoBarCategory(scale: scale))
                .padding(EdgeInsets(top: 6 * scale, leading: 8 * scale, bottom: 2 * scale, trailing: 8 * scale))
                .frame(maxWidth: .infinity, alignment: .leading) // Ensure frame is set before background for correct clipping area
                .background(theme.infoLabelCategoryBackground)
                .clipShape(RoundedCorner(radius: 8 * scale, corners: [.topLeft, .topRight]))
                .foregroundColor(theme.tagText)

            Text(value)
                .font(CardView.NewCardFonts.infoBarValue(scale: scale))
                .padding(EdgeInsets(top: 2 * scale, leading: 8 * scale, bottom: 6 * scale, trailing: 8 * scale))
                .frame(maxWidth: .infinity, alignment: .leading) // Ensure frame is set before background for correct clipping area
                .background(theme.infoLabelValueBackground)
                .clipShape(RoundedCorner(radius: 8 * scale, corners: [.bottomLeft, .bottomRight]))
                .foregroundColor(theme.tagText)
        }
        // Removed clipShape from VStack, individual parts handle their clipping
        .frame(maxWidth: .infinity) // Allows the label to expand and helps with even distribution in parent HStack
    }
}
