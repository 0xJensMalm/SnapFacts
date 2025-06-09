import SwiftUI

struct SnapDexView: View {
    @EnvironmentObject var snapDexManager: SnapDexManager
    @State private var showingCardGenerationView = false // To navigate to card generation
    @State private var cardGenerationStatus: CardGenerationStatus = .none // Manages the state of new card generation
    @State private var newlyGeneratedCard: CardContent? = nil // Holds the card from CameraView
    @State private var shouldNavigateToNewCardView: Bool = false // Triggers navigation to CardView

    // Define grid layout: 3 columns, flexible spacing
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

    var body: some View {
        NavigationView {
            ZStack {
            VStack {
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
                    cardGenerationStatus = .awaitingAPI // Set status before showing camera
                    showingCardGenerationView = true
                }) {
                    Text("Find New Card")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            // New Status Button Overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    statusButton
                        .padding(20) // Adjust padding as needed
                }
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
        .navigationTitle("SnapDex")
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

    // Computed property for the status button's view
    @ViewBuilder
    private var statusButton: some View {
        Button(action: {
            switch cardGenerationStatus {
            case .ready:
                if newlyGeneratedCard != nil {
                    print("Status button tapped: New card ready! Triggering navigation.")
                    shouldNavigateToNewCardView = true
                    // Status and newlyGeneratedCard will be reset by CardView's onDismiss or NavLink's isActive binding
                } else {
                    print("Status button tapped: Ready, but no card data available.")
                    cardGenerationStatus = .none // Reset if something went wrong
                }
            case .awaitingAPI, .none:
                // Button does nothing in these states, or you could show an alert/info.
                print("Status button tapped: Status is \(cardGenerationStatus). No action.")
                break
            }
        }) {
            HStack {
                if let imageName = cardGenerationStatus.systemImageName {
                    Image(systemName: imageName)
                }
                if !cardGenerationStatus.label.isEmpty {
                    Text(cardGenerationStatus.label)
                }
            }
            .padding(cardGenerationStatus == .none ? 10 : 12) // Smaller padding for .none state
            .background(cardGenerationStatus.color)
            .foregroundColor(cardGenerationStatus == .awaitingAPI ? .black : .white) // Yellow bg needs dark text
            .if(cardGenerationStatus == .none) { view in
                view.clipShape(Circle())
            }
            .if(cardGenerationStatus != .none) { view in
                view.clipShape(Capsule())
            }
            .shadow(radius: 5)
            .animation(.spring(), value: cardGenerationStatus) // Animate status changes
        }
        .disabled(cardGenerationStatus == .awaitingAPI || (cardGenerationStatus == .none && cardGenerationStatus.label.isEmpty)) // Disable if awaiting or if .none is just a dot // Potentially disable if .none is just a grey dot with no action
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
        VStack {
            // Placeholder for card image - replace with actual image loading
            if let uiImage = UIImage(named: card.localImageName) ?? loadImageFromFile(imageName: card.localImageName) {
                 Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(Text("No Image").font(.caption))
            }
            Text(card.title)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(5)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
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
