import Foundation

class DataLoader {
    static func loadCategories() -> [Category] {
        guard let url = Bundle.main.url(forResource: "word", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let categories = try? JSONDecoder().decode([Category].self, from: data) else {
            return []
        }
        return categories
    }
    
    static func buildWordMap() -> [String: WordEntry] {
        let categories = loadCategories()
        let allEntries = categories.flatMap { $0.entries }

        var map: [String: WordEntry] = [:]

        for entry in allEntries {
            // Разбиваем на отдельные слова
            let forms = entry.word
                .lowercased()
                .components(separatedBy: .whitespaces)
                .map { $0.trimmingCharacters(in: .punctuationCharacters) }

            for form in forms {
                if !form.isEmpty {
                    map[form] = entry
                }
            }
        }

        return map
    }
}
