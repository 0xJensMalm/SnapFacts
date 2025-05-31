import SwiftUI

@main
struct Snap_FactsApp: App { // Or whatever your app's name is
    var body: some Scene {
        WindowGroup {
            CameraView() // UPDATED: Make CameraView the initial view
        }
    }
}
