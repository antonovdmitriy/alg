import SwiftUI

struct WordListView: View {
    let category: Category

    var body: some View {
        List(category.entries) { entry in
            NavigationLink(destination: WordDetailView(entry: entry, categoryId: category.id.uuidString.lowercased())) {
                Text(entry.word)
            }
        }
        .navigationTitle(retrieveTranslation(from: category.translations))
    }
}
