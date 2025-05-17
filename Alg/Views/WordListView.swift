import SwiftUI

struct WordListView: View {
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    let category: Category

    var body: some View {
        List(category.entries) { entry in
            NavigationLink(destination: WordDetailView(entry: entry, categoryId: category.id.uuidString.lowercased())) {
                Text(entry.word)
            }
        }
        .navigationTitle(retrieveTranslation(from: category.translations, lang: selectedLanguage))
    }
}
