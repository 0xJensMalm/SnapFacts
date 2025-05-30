import SwiftUI

/// A visual skin for the card UI
struct CardType: Identifiable, Equatable {
    let id   = UUID()
    let name: String
    let icon: String          // SF Symbol used in the cycler
    let color: Color          // Fallback / tint color
    let backgroundAsset: String?    // Optional asset name for background
}

extension CardType {
    /// Extend this array with new themes; supply `backgroundAsset`
    /// if you want an image (leave `nil` to use just the color).
    static let all: [CardType] = [
        .init(name: "Classic",
              icon: "circle.fill",
              color: Color.blue.opacity(0.85),
              backgroundAsset: nil),

        .init(name: "Forest",
              icon: "leaf.fill",
              color: Color.green.opacity(0.85),
              backgroundAsset: "forestBG"),   // <- add your Asset here

        .init(name: "Fire",
              icon: "flame.fill",
              color: Color.red.opacity(0.85),
              backgroundAsset: "fireBG"),     // <- add your Asset here

        .init(name: "Night",
              icon: "moon.fill",
              color: Color.indigo.opacity(0.90),
              backgroundAsset: nil)
    ]
}

#if DEBUG
/// Visual preview: shows either color or asset thumbnail
struct CardTypes_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            ForEach(CardType.all) { theme in
                ZStack {
                    if let asset = theme.backgroundAsset,
                       let uiImg = UIImage(named: asset) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    } else {
                        theme.color
                    }

                    HStack(spacing: 8) {
                        Image(systemName: theme.icon)
                        Text(theme.name)
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, minHeight: 60)
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .padding()
        .previewDisplayName("CardType Themes with Backgrounds")
    }
}
#endif
