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
}
