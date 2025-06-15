import SwiftUI

class MatchingGameViewModel: ObservableObject {
    @Published var pairs: [MatchingPair] = []
    @Published var selectedLeft: MatchingPair?
    @Published var selectedRight: MatchingPair?
    @AppStorage("selectedCategories") private var selectedCategoriesData: Data = Data()
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @AppStorage("selectedLanguageLevel") private var selectedLanguageLevel = "all"
    @AppStorage("includeLowerLevels") private var includeLowerLevels = true
    
    private let wordService: WordService
    private let learningStateManager: WordLearningStateManager

    private var shuffledRight: [MatchingPair] = []
    private var availableWords: [WordEntry] = []
    private var activeWordIds: [UUID] = []

    init(wordService: WordService, learningStateManager: WordLearningStateManager) {
        self.wordService = wordService
        self.learningStateManager = learningStateManager
        generatePairs()
    }

    func generatePairs(preserveIds: Bool = false) {
        let selectedCategoryIds = (try? JSONDecoder().decode([UUID].self, from: selectedCategoriesData)) ?? []
        let useAll = selectedCategoryIds.contains(Category.allCategoryId)
        let categories = wordService.allCategories()
        var entries: [WordEntry]

        if useAll {
            let allIgnored = learningStateManager.ignoredWords
            let allKnown = learningStateManager.knownWords
            entries = wordService.allWords()
                .filter { !allIgnored.contains($0.id) && !allKnown.contains($0.id) }
                .filter { ($0.translations[selectedLanguage] ?? "").isEmpty == false }
        } else {
            let allIgnored = learningStateManager.ignoredWords
            let allKnown = learningStateManager.knownWords
            entries = categories
                .filter { selectedCategoryIds.contains($0.id) }
                .flatMap { $0.entries }
                .filter { !allIgnored.contains($0.id) && !allKnown.contains($0.id) }
                .filter { ($0.translations[selectedLanguage] ?? "").isEmpty == false }
                .shuffled()
        }

        // --- CEFR Level Filtering ---
        let allLevels: [CEFRLevel] = [.a1, .a2, .b1, .b2, .c1, .c2]
        let allowedLevels: [CEFRLevel]
        if selectedLanguageLevel == "all" {
            allowedLevels = allLevels
        } else if let selected = CEFRLevel(rawValue: selectedLanguageLevel) {
            if includeLowerLevels {
                if let index = allLevels.firstIndex(of: selected) {
                    allowedLevels = Array(allLevels.prefix(through: index))
                } else {
                    allowedLevels = []
                }
            } else {
                allowedLevels = [selected]
            }
        } else {
            allowedLevels = []
        }

        entries = entries.filter { entry in
            guard let level = entry.level else {
                return selectedLanguageLevel == "all"
            }
            return allowedLevels.contains(level)
        }
        // --- End CEFR Level Filtering ---

        let allEntries = entries

        if preserveIds {
            let entryMap = Dictionary(uniqueKeysWithValues: allEntries.map { ($0.id, $0) })
            pairs = activeWordIds.compactMap { id in
                guard let entry = entryMap[id] else { return nil }
                return MatchingPair(id: entry.id, left: entry.word, right: entry.translations[selectedLanguage] ?? "-")
            }
            // Обновляем availableWords оставшимися словами, которые не используются
            let usedIds = Set(activeWordIds)
            availableWords = allEntries.filter { !usedIds.contains($0.id) }.shuffled()
            shuffledRight = pairs.shuffled()
            // Добираем недостающие пары, если какие-то были удалены
            while pairs.count < 5, let entry = availableWords.popLast() {
                let newPair = MatchingPair(id: entry.id, left: entry.word, right: entry.translations[selectedLanguage] ?? "-")
                pairs.append(newPair)
                activeWordIds.append(entry.id)
                shuffledRight.append(newPair)
            }
        } else {
            availableWords = allEntries.shuffled()
            pairs = []
            shuffledRight = []
            activeWordIds = []

            while pairs.count < 5, let entry = availableWords.popLast() {
                let pair = MatchingPair(id: entry.id, left: entry.word, right: entry.translations[selectedLanguage] ?? "-")
                pairs.append(pair)
                shuffledRight.append(pair)
                activeWordIds.append(entry.id)
            }
            shuffledRight.shuffle()
        }
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

                if let newEntry = availableWords.popLast() {
                    let newPair = MatchingPair(id: newEntry.id, left: newEntry.word, right: newEntry.translations[selectedLanguage] ?? "-")
                    pairs.append(newPair)
                    shuffledRight.append(newPair)
                    shuffledRight.shuffle()
                }
            }
            // Clear selections in either case
            selectedLeft = nil
            selectedRight = nil
        }

        if pairs.allSatisfy({ $0.isMatched }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.generatePairs()
            }
        }
    }
}

struct MatchingPair: Identifiable, Equatable {
    let id: UUID
    let left: String
    let right: String
    var isMatched: Bool = false
}
