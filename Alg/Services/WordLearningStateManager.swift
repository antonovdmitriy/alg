import Foundation

class WordLearningStateManager {

    private let knownKey = "knownWords"
    private let ignoredKey = "ignoredWords"
    private let favoriteKey = "favoriteWords"

    private func getUUIDs(forKey key: String) -> Set<UUID> {
        guard let data = UserDefaults.standard.data(forKey: key),
              let array = try? JSONDecoder().decode([UUID].self, from: data) else {
            return []
        }
        return Set(array)
    }

    private func saveUUIDs(_ set: Set<UUID>, forKey key: String) {
        if let data = try? JSONEncoder().encode(Array(set)) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    var knownWords: Set<UUID> {
        get { getUUIDs(forKey: knownKey) }
        set { saveUUIDs(newValue, forKey: knownKey) }
    }

    var ignoredWords: Set<UUID> {
        get { getUUIDs(forKey: ignoredKey) }
        set { saveUUIDs(newValue, forKey: ignoredKey) }
    }

    var favoriteWords: Set<UUID> {
        get { getUUIDs(forKey: favoriteKey) }
        set { saveUUIDs(newValue, forKey: favoriteKey) }
    }

    func markKnown(_ id: UUID) {
        var set = knownWords
        set.insert(id)
        knownWords = set
    }

    func markIgnored(_ id: UUID) {
        var set = ignoredWords
        set.insert(id)
        ignoredWords = set
    }

    func toggleFavorite(_ id: UUID) {
        var set = favoriteWords
        if set.contains(id) {
            set.remove(id)
        } else {
            set.insert(id)
        }
        favoriteWords = set
    }

    func isFavorite(_ id: UUID) -> Bool {
        favoriteWords.contains(id)
    }

    func isKnown(_ id: UUID) -> Bool {
        knownWords.contains(id)
    }

    func isKnownOrHidden(id: UUID) -> Bool {
        return isKnown(id) || isIgnored(id)
    }

    func isIgnored(_ id: UUID) -> Bool {
        ignoredWords.contains(id)
    }
}
