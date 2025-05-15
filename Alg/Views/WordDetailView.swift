import SwiftUI

struct WordDetailView: View {
    let entry: WordEntry
    let categoryId: String

    var body: some View {
        ScrollView {
            WordCardView(entry: entry, categoryId: categoryId)
        }
        .navigationTitle(entry.word)
        .navigationBarTitleDisplayMode(.inline)
    }
}
