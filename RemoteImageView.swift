import SwiftUI

struct RemoteImageView: View {
    let source: String                // can be asset/SF symbol name or full URL

    var body: some View {
        if source.lowercased().hasPrefix("http") {
            // Existing logic for HTTP/HTTPS URLs
            AsyncImage(url: URL(string: source)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .failure:
                    Image(systemName: "photo.fill") // More generic placeholder
                        .resizable().scaledToFit().foregroundColor(.gray)
                case .success(let img):
                    img.resizable().scaledToFit()
                @unknown default:
                    EmptyView()
                }
            }
        } else if source.lowercased().hasPrefix("file:///") {
            // New logic for file URLs
            if let fileURL = URL(string: source), 
               let imageData = try? Data(contentsOf: fileURL), 
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo.fill") // Placeholder for failed file load
                    .resizable().scaledToFit().foregroundColor(.gray)
            }
        } else {
            // Existing logic for asset names / SF Symbols
            Image(source).resizable().scaledToFit()
        }
    }
}
