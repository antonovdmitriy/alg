import SwiftUI

struct MatchingPair: Identifiable, Equatable {
    let id: UUID
    let left: String
    let right: String
    var isMatched: Bool = false
}

class MatchingGameViewModel: ObservableObject {
    @Published var pairs: [MatchingPair] = []
    @Published var selectedLeft: MatchingPair?
    @Published var selectedRight: MatchingPair?
    
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    
    private let wordService: WordService
    private let learningStateManager: WordLearningStateManager

    private var shuffledRight: [MatchingPair] = []
    private var availableWords: [WordEntry] = []

    init(wordService: WordService, learningStateManager: WordLearningStateManager) {
        self.wordService = wordService
        self.learningStateManager = learningStateManager
        generatePairs()
    }

    func generatePairs() {
        let allIgnored = learningStateManager.ignoredWords
        let allKnown = learningStateManager.knownWords
        let allEntries = wordService.allWords()

        availableWords = allEntries.filter { !allIgnored.contains($0.id) && !allKnown.contains($0.id) }.shuffled()

        pairs = []
        shuffledRight = []

        while pairs.count < 10, let entry = availableWords.popLast() {
            let pair = MatchingPair(id: entry.id, left: entry.word, right: entry.translations[selectedLanguage] ?? "-")
            pairs.append(pair)
            shuffledRight.append(pair)
        }

        shuffledRight.shuffle()
    }

    var leftColumn: [MatchingPair] {
        pairs.filter { !$0.isMatched }
    }

    var rightColumn: [MatchingPair] {
        shuffledRight.filter { !$0.isMatched }
    }

    func select(pair: MatchingPair, isLeft: Bool) {
        if isLeft {
            if selectedLeft?.id == pair.id {
                selectedLeft = nil
            } else {
                selectedLeft = pair
            }
        } else {
            if selectedRight?.id == pair.id {
                selectedRight = nil
            } else {
                selectedRight = pair
            }
        }

        if let left = selectedLeft, let right = selectedRight {
            if left.id == right.id {
                if let idx = pairs.firstIndex(where: { $0.id == left.id }) {
                    pairs[idx].isMatched = true
                }
                if let idx = shuffledRight.firstIndex(where: { $0.id == right.id }) {
                    shuffledRight[idx].isMatched = true
                }
                selectedLeft = nil
                selectedRight = nil

                if let newEntry = availableWords.popLast() {
                    let newPair = MatchingPair(id: newEntry.id, left: newEntry.word, right: newEntry.translations[selectedLanguage] ?? "-")
                    pairs.append(newPair)
                    shuffledRight.append(newPair)
                }
            }
        }

        if pairs.allSatisfy({ $0.isMatched }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.generatePairs()
            }
        }
    }
}

struct MatchingGameView: View {
    let wordService: WordService
    let learningStateManager: WordLearningStateManager

    @StateObject private var viewModel: MatchingGameViewModel

    init(wordService: WordService, learningStateManager: WordLearningStateManager) {
        _viewModel = StateObject(wrappedValue: MatchingGameViewModel(wordService: wordService, learningStateManager: learningStateManager))
        self.wordService = wordService
        self.learningStateManager = learningStateManager
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            HStack(spacing: 30) {
                VStack(spacing: 12) {
                    ForEach(viewModel.leftColumn) { pair in
                        Text(pair.left)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                            .background(viewModel.selectedLeft?.id == pair.id ? Color.green.opacity(0.3) : Color.white.opacity(0.8))
                            .cornerRadius(8)
                            .onTapGesture {
                                viewModel.select(pair: pair, isLeft: true)
                            }
                    }
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.rightColumn) { pair in
                        Text(pair.right)
                            .font(.body)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                            .background(viewModel.selectedRight?.id == pair.id ? Color.green.opacity(0.3) : Color.white.opacity(0.8))
                            .cornerRadius(8)
                            .onTapGesture {
                                viewModel.select(pair: pair, isLeft: false)
                            }
                    }
                }
            }
            .padding()
        }
    }
}
