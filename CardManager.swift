import SwiftUI

@MainActor
final class CardManager: ObservableObject {
    @Published private(set) var current: CardType = CardType.all.first!

    /// Cycle forward through the available card types.
    func next() {
        guard let idx = CardType.all.firstIndex(of: current) else { return }
        let nextIdx = CardType.all.index(after: idx)
        current = CardType.all[nextIdx == CardType.all.endIndex ? 0 : nextIdx]
    }
}
