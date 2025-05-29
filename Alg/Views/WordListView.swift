import SwiftUI

struct WordListView: View {
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    let category: Category
    let wordService: WordService
    @Environment(\.locale) private var locale

    var body: some View {
        List(category.entries) { entry in
            NavigationLink(destination: WordDetailView(entry: entry, categoryId: category.id.uuidString.lowercased(), wordService: wordService)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.word)
                        .font(.headline)
                    if let translation = entry.translations[selectedLanguage] {
                        Text(translation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle((category.translations[locale.language.languageCode?.identifier ?? ""] ?? category.translations["en"] ?? "").capitalized)
    }
}
