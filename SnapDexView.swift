import SwiftUI

struct SnapDexView: View {
    @EnvironmentObject var snapDexManager: SnapDexManager
    @State private var showingCardGenerationView = false // To navigate to card generation
    @State private var cardGenerationStatus: CardGenerationStatus = .none // Manages the state of new card generation
    @State private var newlyGeneratedCard: CardContent? = nil // Holds the card from CameraView
    @State private var shouldNavigateToNewCardView: Bool = false // Triggers navigation to CardView
    @State private var animateGradient = false

    // Define grid layout: 2 columns, flexible spacing
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)

    private var buttonText: String {
        switch cardGenerationStatus {
        case .none:
            return "Catch new creature!"
        case .awaitingAPI:
            return "Processing..."
        case .ready:
            return "New Creature Captured!"
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

            VStack {
                Image("snapFacts")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100) // Scaled up 2.5x from 40
                    .padding(.bottom, 10)

                if snapDexManager.collectedCards.isEmpty {
                    VStack {
                        Spacer()
                        Text("Your SnapDex is empty.")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Go find some cards!")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(snapDexManager.collectedCards) { card in
                                NavigationLink(destination: CardView(cardContent: card, isFromSnapDex: true)) { // Assuming CardView can be initialized this way
                                    SnapDexCardCell(card: card)
                                }
                            }
                        }
                        .padding()
                    }
                }

                Spacer() // Pushes the button to the bottom

                Button(action: {
                    switch cardGenerationStatus {
                    case .none:
                        cardGenerationStatus = .awaitingAPI
                        showingCardGenerationView = true
                    case .ready:
                        shouldNavigateToNewCardView = true
                    case .awaitingAPI:
                        // Button is disabled, no action
                        break
                    }
                }) {
                    HStack {
                        if cardGenerationStatus == .awaitingAPI {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "camera.viewfinder")
                        }
                        Text(buttonText)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue.opacity(0.8), Color.pink]),
                            startPoint: animateGradient ? .topLeading : .bottomTrailing,
                            endPoint: animateGradient ? .bottomTrailing : .topLeading
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .purple.opacity(0.7), radius: 10, y: 5)
                    .onAppear {
                        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                            animateGradient = true
                        }
                    }
                }
                .disabled(cardGenerationStatus == .awaitingAPI)
                .padding()
            }

            .background(
                // NavigationLink for the new card, activated programmatically
                NavigationLink(destination: CardView(cardContent: newlyGeneratedCard ?? SampleCardData.vansOldSkool, isFromSnapDex: false, onDismiss: {
                    print("[SnapDexView] CardView onDismiss (from NavigationLink): Called. Current status: \(self.cardGenerationStatus). Resetting newlyGeneratedCard and status to .none.")
                    self.newlyGeneratedCard = nil
                    self.cardGenerationStatus = .none
                }),
                               isActive: $shouldNavigateToNewCardView) {
                    EmptyView()
                }
            )
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCardGenerationView, onDismiss: {
            print("[SnapDexView] CameraView Sheet: onDismiss called. Current status: \(self.cardGenerationStatus).")
            // This onDismiss is called when CameraView dismisses itself or is manually dismissed.
            // We no longer want to automatically reset .awaitingAPI to .none here,
            // as failures should keep the button yellow (processing).
            // If the user manually dismisses CameraView *before* confirming a picture,
            // the status will remain .awaitingAPI, and they can tap the yellow button to try again.
        }) {
                // This is where you would present your Camera/Card Generation View
                // For now, let's use a placeholder or your existing CardGenerationView if it's ready
                // CardGeneratorView() or a similar view
                CameraView { result in // Completion handler from CameraView
                    showingCardGenerationView = false // Dismiss the sheet first
                    switch result {
                    case .success(let card):
                        print("[SnapDexView] CameraView Completion: .success. Current status: \(self.cardGenerationStatus). Setting newlyGeneratedCard and status to .ready.")
                        self.newlyGeneratedCard = card
                        self.cardGenerationStatus = .ready
                        // Optionally, immediately trigger navigation if desired, or wait for button tap
                        // self.shouldNavigateToNewCardView = true
                    case .failure(let error):
                        print("[SnapDexView] CameraView Completion: .failure. Error: \(error.localizedDescription). Current status: \(self.cardGenerationStatus). Status will NOT be changed here.")
                        // Do not change cardGenerationStatus here. It should remain .awaitingAPI.
                        // self.cardGenerationStatus = .none // Removed this line
                    }
                }
                .environmentObject(snapDexManager)
                .environmentObject(ThemeManager())
            }
        }
    }


}

// Helper for conditional modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct SnapDexCardCell: View {
    let card: CardContent

    var body: some View {
        VStack(spacing: 0) {
            // --- FRAMED IMAGE CONTAINER ---
            ZStack {
                // Frame background color
                Color(UIColor.systemGray6)

                if let uiImage = UIImage(named: card.localImageName) ?? loadImageFromFile(imageName: card.localImageName) {
                     Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .padding(4) // Padding creates the frame
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.white))
                }
            }
            .aspectRatio(1.0, contentMode: .fit) // Make image container square
            .clipped()

            // --- INFO SECTION ---
            HStack {
                Text(card.title)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let typeStat = card.stats.first {
                    Text(typeStat.value.displayString.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(5)
                        .lineLimit(1)
                }
            }
            .padding(8)
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // Helper function to load image from file system if not in asset catalog
    // This assumes localImageName might be a file path URL string or just a name
    private func loadImageFromFile(imageName: String) -> UIImage? {
        // Check if imageName is a full file path URL
        if let url = URL(string: imageName), url.isFileURL {
            if let data = try? Data(contentsOf: url) {
                return UIImage(data: data)
            }
        } else {
            // Assume it's a name in the documents directory (adjust path as needed)
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(imageName)
            if let data = try? Data(contentsOf: fileURL) {
                return UIImage(data: data)
            }
        }
        return nil
    }
}

struct SnapDexView_Previews: PreviewProvider {
    static var previews: some View {
        SnapDexView()
            .environmentObject(SnapDexManager()) // Provide a dummy manager for preview
    }
}
