import Foundation
import SwiftUI

@MainActor
class RandomWordViewModel: ObservableObject {
    @Published var currentEntry: WordEntry
    @Published var currentCategoryId: UUID
    @Published var nextPrefetchedEntry: WordEntry?
    @Published var nextPrefetchedCategoryId: UUID?
    @Published var showCard = false
    @Published var feedbackMessage: String?
    @Published var showGoalCelebration = false
    @Published var showGoalVideo = false
    @Published var exampleIndex: Int?

    private let wordService: WordService
    private let learningStateManager: WordLearningStateManager
    private let audioPlayerHelper: AudioPlayerHelper
    private let selectedCategoriesData: Data
    private let playSoundOnWordChange: Bool
    private let autoAdvanceAfterAction: Bool
    private let showExamplesAfterWord: Bool
    private let examplesToShowCount: Int

    private struct HistoryItem {
        enum Kind {
            case word(WordEntry, UUID)
            case example(WordEntry, UUID, Int)
        }
        let kind: Kind
    }

    private var history: [HistoryItem] = []
    private var historyIndex: Int = -1

    init(
        wordService: WordService,
        learningStateManager: WordLearningStateManager,
        audioPlayerHelper: AudioPlayerHelper,
        selectedCategoriesData: Data,
        playSoundOnWordChange: Bool,
        autoAdvanceAfterAction: Bool,
        showExamplesAfterWord: Bool,
        examplesToShowCount: Int
    ) {
        self.wordService = wordService
        self.learningStateManager = learningStateManager
        self.audioPlayerHelper = audioPlayerHelper
        self.selectedCategoriesData = selectedCategoriesData
        self.playSoundOnWordChange = playSoundOnWordChange
        self.autoAdvanceAfterAction = autoAdvanceAfterAction
        self.showExamplesAfterWord = showExamplesAfterWord
        self.examplesToShowCount = examplesToShowCount
        
        let placeholder = WordEntry(id: UUID(), word: "", version: -1, voiceEntries: nil, forms: [], translations: [:], examples: [], phoneme: nil)
        self._currentEntry = Published(initialValue: placeholder)
        self._currentCategoryId = Published(initialValue: UUID())
    }

    func initialize() {
        let selectedIds = (try? JSONDecoder().decode([UUID].self, from: selectedCategoriesData)) ?? []
        let (entry, catId) = pickRandomEntry(from: selectedIds)
        currentEntry = entry
        currentCategoryId = catId
        history = [HistoryItem(kind: .word(entry, catId))]
        historyIndex = 0
        prefetchNextEntry(using: selectedIds)
        if playSoundOnWordChange {
            audioPlayerHelper.playAudio(entryId: entry.id)
        }
    }

    private func pickRandomEntry(from selectedCategoryIds: [UUID]) -> (WordEntry, UUID) {
        let categories = wordService.allCategories()
        let useAll = selectedCategoryIds.contains(Category.allCategoryId)
        let otherIds = selectedCategoryIds.filter { $0 != Category.allCategoryId }

        var categoryChoices: [UUID] = []
        if useAll { categoryChoices.append(Category.allCategoryId) }
        categoryChoices.append(contentsOf: otherIds)

        let chosenCategoryId = categoryChoices.randomElement()!
        let chosenCategory: Category

        if chosenCategoryId == Category.allCategoryId {
            chosenCategory = categories.randomElement()!
        } else {
            guard let found = categories.first(where: { $0.id == chosenCategoryId }) else {
                fatalError("Category not found")
            }
            chosenCategory = found
        }

        let ignored = learningStateManager.ignoredWords
        let known = learningStateManager.knownWords
        let filtered = chosenCategory.entries.filter { !ignored.contains($0.id) && !known.contains($0.id) }

        if let entry = filtered.randomElement() {
            return (entry, chosenCategory.id)
        } else {
            let placeholder = WordEntry(
                id: UUID(),
                word: NSLocalizedString("all_words_completed_title", comment: ""),
                version: -1,
                voiceEntries: nil,
                forms: [],
                translations: ["ru": "Вы прошли все слова", "en": "You've completed all words"],
                examples: [],
                phoneme: nil
            )
            return (placeholder, chosenCategory.id)
        }
    }

    private func prefetchNextEntry(using selectedIds: [UUID]) {
        DispatchQueue.global(qos: .utility).async {
            let (entry, catId) = self.pickRandomEntry(from: selectedIds)
            if self.playSoundOnWordChange {
                self.audioPlayerHelper.prefetchAudio(entryId: entry.id)
            }
            DispatchQueue.main.async {
                self.nextPrefetchedEntry = entry
                self.nextPrefetchedCategoryId = catId
            }
        }
    }
    
    func isKnown(_ id: UUID) -> Bool {
        learningStateManager.isKnown(id)
    }

    func isIgnored(_ id: UUID) -> Bool {
        learningStateManager.isIgnored(id)
    }

    func isFavorite(_ id: UUID) -> Bool {
        learningStateManager.isFavorite(id)
    }
}
