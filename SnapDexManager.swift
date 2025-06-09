import Foundation
import SwiftUI

class SnapDexManager: ObservableObject {
    @Published var collectedCards: [CardContent] = []

    private let userDefaultsKey = "snapDexCards"

    init() {
        loadCards()
    }

    func addCard(_ card: CardContent) {
        // Prevent duplicates based on ID
        if !collectedCards.contains(where: { $0.id == card.id }) {
            collectedCards.append(card)
            saveCards()
        }
    }

    func releaseCard(_ card: CardContent) {
        collectedCards.removeAll { $0.id == card.id }
        saveCards()
    }
    
    func releaseCard(at offsets: IndexSet) {
        collectedCards.remove(atOffsets: offsets)
        saveCards()
    }

    private func saveCards() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(collectedCards)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Error saving cards to UserDefaults: \(error)")
        }
    }

    private func loadCards() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            collectedCards = try decoder.decode([CardContent].self, from: data)
        } catch {
            print("Error loading cards from UserDefaults: \(error)")
        }
    }
    
    // Helper to check if a card is already collected
    func isCardCollected(_ card: CardContent) -> Bool {
        return collectedCards.contains(where: { $0.id == card.id })
    }
}
