import SwiftUI

struct RemoteImageView: View {
    let source: String                // can be asset/SF symbol name or full URL

    var body: some View {
        if source.lowercased().hasPrefix("http") {
            AsyncImage(url: URL(string: source)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .failure:
                    Image(systemName: "exclamationmark.triangle")
                        .resizable().scaledToFit().foregroundColor(.red)
                case .success(let img):
                    img.resizable().scaledToFit()
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(source).resizable().scaledToFit()
        }
    }
}
