import SwiftUI

struct FavoriteWordsView: View {
    let wordService: WordService
    let learningStateManager: WordLearningStateManager
    let audioHelper: AudioPlayerHelper
    @State private var words: [(WordEntry, UUID)] = []

    var body: some View {
        FilteredWordListView(
            title: NSLocalizedString("settings_favorite_words", comment: ""),
            entries: words,
            onDelete: { id in
                learningStateManager.toggleFavorite(id)
                words.removeAll { $0.0.id == id }
            },
            onClear: {
                learningStateManager.favoriteWords = []
                words = []
            },
            wordService: wordService,
            learningStateManager: learningStateManager,
            audioPlayerHelper: audioHelper
        )
        .onAppear {
            //TODO: rewrite when there will be index.
            words = wordService.allWords().compactMap { entry in
                let id = entry.id
                return learningStateManager.favoriteWords.contains(id) ? (entry, id) : nil
            }
        }
    }
}
