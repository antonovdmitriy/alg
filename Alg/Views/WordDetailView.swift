import SwiftUI

struct WordDetailView: View {
    let entry: WordEntry
    let categoryId: String
    let wordService: WordService
    let learningStateManager: WordLearningStateManager
    
    var body: some View {
        ScrollView {
            WordCardView(
                entry: entry,
                categoryId: categoryId,
                wordService: wordService,
                learningStateManager: learningStateManager
            )
        }
        .navigationTitle(entry.word)
        .navigationBarTitleDisplayMode(.inline)
    }
}
