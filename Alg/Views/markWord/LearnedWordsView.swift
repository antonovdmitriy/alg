import SwiftUI

struct LearnedWordsView: View {
    let wordService: WordService
    let learningStateManager: WordLearningStateManager
    let audioHelper: AudioPlayerHelper
    @State private var words: [(WordEntry, UUID)] = []

    var body: some View {
        FilteredWordListView(
            title: NSLocalizedString("settings_learned_words", comment: ""),
            entries: words,
            onDelete: { id in
                var set = learningStateManager.knownWords
                set.remove(id)
                learningStateManager.knownWords = set
                words.removeAll { $0.0.id == id }
            },
            onClear: {
                learningStateManager.knownWords = []
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
                return learningStateManager.knownWords.contains(id) ? (entry, id) : nil
            }
        }
    }
}
