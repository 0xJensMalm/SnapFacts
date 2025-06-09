import SwiftUI

struct SnapDexView: View {
    @EnvironmentObject var snapDexManager: SnapDexManager
    @State private var showingCardGenerationView = false // To navigate to card generation

    // Define grid layout: 3 columns, flexible spacing
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

    var body: some View {
        NavigationView {
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
            .navigationTitle("SnapDex")
            .sheet(isPresented: $showingCardGenerationView) {
                // This is where you would present your Camera/Card Generation View
                // For now, let's use a placeholder or your existing CardGenerationView if it's ready
                // CardGeneratorView() or a similar view
                CameraView() // Present the CameraView for new card generation
                    .environmentObject(snapDexManager) // Pass along if needed by CameraView or subsequent views
                    .environmentObject(ThemeManager()) // Assuming CameraView might also need ThemeManager
            }
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
