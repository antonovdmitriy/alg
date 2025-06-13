import SwiftUI

struct WordDetailView: View {
    let entry: WordEntry
    let categoryId: String
    let wordService: WordService
    let learningStateManager: WordLearningStateManager
    let audioPlayerHelper: AudioPlayerHelper
    
    var body: some View {
        ScrollView {
            WordCardView(
                entry: entry,
                categoryId: categoryId,
                wordService: wordService,
                learningStateManager: learningStateManager,
                audioPlayerHelper: audioPlayerHelper
            )
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
