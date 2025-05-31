import SwiftUI

struct WordDetailView: View {
    let entry: WordEntry
    let categoryId: String
    let wordService: WordService

    var body: some View {
        ScrollView {
            WordCardView(
                entry: entry,
                categoryId: categoryId,
                wordService: wordService
            )
        }
        .navigationTitle(entry.word)
        .navigationBarTitleDisplayMode(.inline)
    }
}
