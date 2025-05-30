import SwiftUI

struct ContentView: View {
    @StateObject private var cardMgr = CardManager()

    var body: some View {
        GeometryReader { geo in
            // ─── CARD UI ─────────────────────────────────────────────
            ZStack {
                VStack(spacing: 0) {

                    // Title
                    Text("Snapachu")
                        .font(GlobalConfig.titleFont)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.top, geo.safeAreaInsets.top + GlobalConfig.titleTopPadding)
                        .padding(.horizontal, GlobalConfig.titleHorizontalPadding)

                    // Rails + Image window
                    topImageSection(height: geo.size.height *
                                    GlobalConfig.topSectionHeightRatio,
                                    geo: geo)

                    // Description + Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("A friendly creature that loves data.")
                            .font(.caption)
                            .foregroundColor(.white)

                        Text("Stats")
                            .font(.headline)
                            .foregroundColor(.white)

                        LazyVGrid(columns: [.init(.flexible()),
                                            .init(.flexible())],
                                  spacing: GlobalConfig.statsGridSpacing) {
                            StatBlockView(title: "Intelligence", value: "82")
                            StatBlockView(title: "Speed",        value: "74")
                            StatBlockView(title: "Cuteness",     value: "95")
                            StatBlockView(title: "Stamina",      value: "88")
                        }
                    }
                    .padding(.horizontal, GlobalConfig.statsHorizontalPadding)
                    .padding(.top, 24)

                    Spacer()

                    // Card-type cycler
                    Button { cardMgr.next() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: cardMgr.current.icon)
                            Text(cardMgr.current.name)
                                .font(.callout.weight(.semibold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.20))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.30), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom,
                             geo.safeAreaInsets.bottom + GlobalConfig.bottomCyclerPadding)
                }
            }
            // ─── BACKDROP (image or color, never affects layout) ─────
            .background( backdrop(for: cardMgr.current) )
        }
    }

    // MARK: – Backdrop helper
    private func backdrop(for card: CardType) -> some View {
        Group {
            if let asset = card.backgroundAsset,
               UIImage(named: asset) != nil {
                Image(asset)
                    .resizable()
                    .scaledToFill()
            } else {
                card.color
            }
        }
        .ignoresSafeArea()
    }

    // MARK: – Top rails + image helper
    private func topImageSection(height: CGFloat, geo: GeometryProxy) -> some View {
        let winWidth  = geo.size.width * GlobalConfig.imageWidthScale
        let winHeight = height * GlobalConfig.imageHeightMultiplier

        return ZStack {
            // Side rails
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(GlobalConfig.railOpacity))
                    .frame(width: GlobalConfig.sideRailWidth, height: height)
                Spacer(minLength: 0)
                Rectangle()
                    .fill(Color.white.opacity(GlobalConfig.railOpacity))
                    .frame(width: GlobalConfig.sideRailWidth, height: height)
            }

            // Image window
            ZStack {
                RoundedRectangle(cornerRadius: GlobalConfig.imageCornerRadius)
                    .fill(Color.white.opacity(GlobalConfig.frameFillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: GlobalConfig.imageCornerRadius)
                            .stroke(Color.white.opacity(GlobalConfig.frameStrokeOpacity), lineWidth: 1)
                    )

                Image(systemName: "photo")          // placeholder
                    .resizable()
                    .scaledToFit()
                    .frame(width: winWidth * 0.55)
            }
            .frame(width: winWidth, height: winHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: height)
    }
}

// MARK: – Local StatBlockView
private struct StatBlockView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 0) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.15))

            Text(value)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.25))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.30), lineWidth: 1)
        )
    }
}

#Preview("iPhone 15 Pro") {
    ContentView()
        .previewDevice("iPhone 15 Pro")
}
