import SwiftUI
import AVKit
import AVFoundation

struct RandomWordView: View {
    @Binding var showTabBar: Bool
    private let wordService: WordService
    private let learningStateManager: WordLearningStateManager
    private let audioPlayerHelper: AudioPlayerHelper
    @AppStorage("selectedCategories") private var selectedCategoriesData: Data = Data()
    @AppStorage("playSoundOnWordChange") private var playSoundOnWordChange = true
    @AppStorage("autoAdvanceAfterAction") private var autoAdvanceAfterAction = true
    @AppStorage("showExamplesAfterWord") private var showExamplesAfterWord = false
    @AppStorage("examplesToShowCount") private var examplesToShowCount = 3
    // These are intentionally left for other usages, but NOT updated by the settings view directly anymore
    @AppStorage("selectedLanguageLevel") private var selectedLanguageLevel = "all"
    @AppStorage("includeLowerLevels") private var includeLowerLevels = true

    @State private var previousLanguageLevel = "all"
    @State private var previousIncludeLowerLevels = true
    
    @State private var currentEntry: WordEntry
    @State private var currentCategoryId: UUID
    @State private var nextPrefetchedEntry: WordEntry?
    @State private var nextPrefetchedCategoryId: UUID?
    @State private var showCard = false
    @State private var lastTapDate = Date.distantPast
    private let tapThreshold: TimeInterval = 0.4
    @State private var feedbackMessage: String?
    @State private var showGoalCelebration = false
    @State private var showGoalVideo = false
    @State private var exampleIndex: Int? = nil
    @State private var shownExampleIndices: [Int] = []
    @State private var history: [HistoryItem] = []
    @State private var historyIndex: Int = 0
    
    init(showTabBar: Binding<Bool>, wordService: WordService, learningStateManager: WordLearningStateManager, audioPlayerHelper: AudioPlayerHelper) {
        self._showTabBar = showTabBar
        self.wordService = wordService
        self.learningStateManager = learningStateManager
        self.audioPlayerHelper = audioPlayerHelper
        _currentCategoryId = State(initialValue: UUID())
        _currentEntry = State(initialValue: WordEntry(id: UUID(), word: "", version: -1, voiceEntries: nil, forms: [], translations: [:], level: nil, examples: [], phoneme: nil))
    }
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
            }
            .onAppear {
                LearningGoalManager.shared.resetIfNewDay()
            }
            
            WordPreviewView(
                entry: currentEntry,
                categoryId: currentCategoryId.uuidString.lowercased(),
                overrideText: .constant(
                    exampleIndex != nil && currentEntry.examples.indices.contains(exampleIndex!)
                    ? "“\(currentEntry.examples[exampleIndex!].text)”"
                    : (showGoalCelebration ? NSLocalizedString("goal_completed_message", comment: "") : nil)
                )
            )
            .edgesIgnoringSafeArea(.all)
            
            if !showTabBar && !showGoalVideo && !showGoalCelebration {
                Image(systemName: "chevron.compact.up")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 20)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            }
            
            if let message = feedbackMessage, !showGoalVideo {
                Text(message)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundColor(.primary)
                    .transition(.opacity)
                    .padding(.bottom, 100)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            
            if showTabBar && !showGoalVideo {
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Button(action: {
                                if !learningStateManager.isKnown(currentEntry.id) {
                                    learningStateManager.toggleKnown(currentEntry.id)
                                    feedbackMessage = NSLocalizedString("marked_as_known", comment: "")
                                } else {
                                    learningStateManager.toggleKnown(currentEntry.id)
                                    feedbackMessage = NSLocalizedString("unmarked_as_known", comment: "")
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {}
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    feedbackMessage = nil
                                    if autoAdvanceAfterAction{
                                        showNextWord()
                                    }
                                }
                            }) {
                                Image(systemName: learningStateManager.isKnown(currentEntry.id) ? "checkmark.circle.fill" : "checkmark")
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(Color.primary.opacity(0.85))
                                    .background(.ultraThinMaterial, in: Circle())
                                    .shadow(radius: 2)
                            }

                            Button(action: {
                                if !learningStateManager.isIgnored(currentEntry.id) {
                                    learningStateManager.toggleIgnored(currentEntry.id)
                                    feedbackMessage = NSLocalizedString("marked_as_ignored", comment: "")
                                } else {
                                    learningStateManager.toggleIgnored(currentEntry.id)
                                    feedbackMessage = NSLocalizedString("unmarked_as_ignored", comment: "")
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {}
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    feedbackMessage = nil
                                    if autoAdvanceAfterAction{
                                        showNextWord()
                                    }
                                }
                            }) {
                                Image(systemName: learningStateManager.isIgnored(currentEntry.id) ? "eye.slash" : "eye")
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(Color.primary.opacity(0.85))
                                    .background(.ultraThinMaterial, in: Circle())
                                    .shadow(radius: 2)
                            }
                            
                            Button(action: {
                                let isAlreadyFavorite = learningStateManager.isFavorite(currentEntry.id)
                                learningStateManager.toggleFavorite(currentEntry.id)
                                feedbackMessage = isAlreadyFavorite ? NSLocalizedString("removed_from_favorites", comment: "") : NSLocalizedString("added_to_favorites", comment: "")
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {}
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    feedbackMessage = nil
                                    if autoAdvanceAfterAction{
                                        showNextWord()
                                    }
                                }
                            }) {
                                Image(systemName: learningStateManager.isFavorite(currentEntry.id) ? "star.fill" : "star")
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(Color.primary.opacity(0.85))
                                    .background(.ultraThinMaterial, in: Circle())
                                    .shadow(radius: 2)
                            }
                        }
                        .padding(.top, 60)
                        .padding(.trailing)
                    }
                    Spacer()
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            if showGoalCelebration && !showGoalVideo {
                Color.clear
                    .onAppear {
                        showTabBar = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            showGoalCelebration = false
                            withAnimation {
                                showGoalVideo = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                showGoalVideo = false
                                proceedToNextWord()
                            }
                        }
                        currentEntry = WordEntry(id: UUID(), word: "", version: -1, voiceEntries: nil, forms: [], translations: [:],  level: nil, examples: [],  phoneme: nil)
                        currentCategoryId = UUID()
                    }
            }
            
            if showGoalVideo {
                FullScreenVideoPlayer(player: AVPlayer(url: Bundle.main.url(forResource: "alg_celebrate", withExtension: "mp4")!))
                    .edgesIgnoringSafeArea(.all)
                    .opacity(showGoalVideo ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0), value: showGoalVideo)
            }
        }
        .onTapGesture {
            guard !showGoalCelebration && !showGoalVideo else { return }
            let now = Date()
            if now.timeIntervalSince(lastTapDate) > tapThreshold {
                lastTapDate = now
                withAnimation {
                    showTabBar.toggle()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            LearningGoalManager.shared.resetIfNewDay()
        }
        .onAppear {
            showTabBar = false
            if currentEntry.word.isEmpty {
                let selectedIds = (try? JSONDecoder().decode([UUID].self, from: selectedCategoriesData)) ?? []
                let (randomEntry, randomCategoryId) = pickRandomEntry(wordService: wordService, learningStateManager: learningStateManager, selectedCategoryIds: selectedIds)
                currentEntry = randomEntry
                currentCategoryId = randomCategoryId
                // Prefetch next word
                let (prefetchedEntry, prefetchedCategoryId) = pickRandomEntry(wordService: wordService, learningStateManager: learningStateManager,  selectedCategoryIds: selectedIds)
                nextPrefetchedEntry = prefetchedEntry
                nextPrefetchedCategoryId = prefetchedCategoryId
                
                if playSoundOnWordChange {
                    DispatchQueue.global(qos: .utility).async {
                        audioPlayerHelper.prefetchAudio(entryId: prefetchedEntry.id)
                    }
                }
            }
            // Initialize history with the current word
            if history.isEmpty {
                history.append(HistoryItem(kind: .word(currentEntry, currentCategoryId)))
            }
            
            if playSoundOnWordChange {
                if let idx = exampleIndex {
                    audioPlayerHelper.playExample(entryId: currentEntry.id, exampleIndex: idx + 1)
                } else {
                    audioPlayerHelper.playAudio(entryId: currentEntry.id)
                }
            }
            // Initialize previous values for language level and includeLowerLevels
            previousLanguageLevel = selectedLanguageLevel
            previousIncludeLowerLevels = includeLowerLevels
        }
        .onChange(of: selectedLanguageLevel) { _, newValue in
            if newValue != previousLanguageLevel {
                previousLanguageLevel = newValue
                // Ensure the selected topic matches the new word level filters
                let selectedIds = (try? JSONDecoder().decode([UUID].self, from: selectedCategoriesData)) ?? []
                let (newEntry, newCategoryId) = pickRandomEntry(wordService: wordService, learningStateManager: learningStateManager, selectedCategoryIds: selectedIds)
                currentCategoryId = newCategoryId
                nextPrefetchedEntry = newEntry
                nextPrefetchedCategoryId = newCategoryId
                if playSoundOnWordChange {
                    audioPlayerHelper.prefetchAudio(entryId: newEntry.id)
                }
            }
        }
        .onChange(of: includeLowerLevels) { _, newValue in
            if newValue != previousIncludeLowerLevels {
                previousIncludeLowerLevels = newValue
                // Ensure the selected topic matches the new word level filters
                let selectedIds = (try? JSONDecoder().decode([UUID].self, from: selectedCategoriesData)) ?? []
                let (newEntry, newCategoryId) = pickRandomEntry(wordService: wordService, learningStateManager: learningStateManager, selectedCategoryIds: selectedIds)
                currentCategoryId = newCategoryId
                nextPrefetchedEntry = newEntry
                nextPrefetchedCategoryId = newCategoryId
                if playSoundOnWordChange {
                    audioPlayerHelper.prefetchAudio(entryId: newEntry.id)
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    guard !showGoalCelebration && !showGoalVideo else { return }
                    if isSwipeUp(value) {
                        showWordCard()
                    } else if isSwipeLeft(value) {
                        showNextWord()
                    } else if isSwipeRight(value), historyIndex > 0 {
                        showPreviousWord()
                    }
                }
        )
        .sheet(isPresented: $showCard) {
            WordCardView(
                entry: currentEntry,
                categoryId: currentCategoryId.uuidString.lowercased(),
                wordService: wordService,
                learningStateManager: learningStateManager,
                audioPlayerHelper: audioPlayerHelper
            )
            .onDisappear {
                showTabBar = false
            }
        }
        .toolbar(showTabBar ? .visible : .hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func pickRandomEntry(wordService: WordService, learningStateManager: WordLearningStateManager, selectedCategoryIds: [UUID]) -> (WordEntry, UUID) {
        let categories = wordService.allCategories()
        let useAll = selectedCategoryIds.contains(Category.allCategoryId)
        let otherIds = selectedCategoryIds.filter { $0 != Category.allCategoryId }

        var selectedCategories: [Category] = []
        if useAll {
            selectedCategories = categories
        } else {
            selectedCategories = categories.filter { cat in otherIds.contains(cat.id) }
        }

        // Allowed levels logic unchanged
        let allLevels: [CEFRLevel] = [.a1, .a2, .b1, .b2, .c1, .c2]
        let allowedLevels: [CEFRLevel]
        if self.selectedLanguageLevel == "all" {
            allowedLevels = allLevels
        } else if let selected = CEFRLevel(rawValue: self.selectedLanguageLevel) {
            if self.includeLowerLevels {
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
        print("Allowed levels:", allowedLevels.map(\.rawValue))

        // Filter categories that have at least one entry matching CEFR filter
        let eligibleCategories = selectedCategories.filter { category in
            category.entries.contains { entry in
                guard let level = entry.level else {
                    return selectedLanguageLevel == "all"
                }
                return allowedLevels.contains(level)
            }
        }
        print("Eligible categories count after CEFR filtering: \(eligibleCategories.count)")
        guard let category = eligibleCategories.randomElement() else {
            print("No eligible categories found with entries matching level filter.")
            // Return placeholder in this case
            let placeholderEntry = WordEntry(
                id: UUID(),
                word: NSLocalizedString("all_words_completed_title", comment: ""),
                version: -1,
                voiceEntries: nil,
                forms: [],
                translations: ["ru": "Вы прошли все слова", "en": "You've completed all words"],
                level: nil,
                examples: [],
                phoneme: nil
            )
            // Pick any category id, fallback to allCategoryId
            let categoryId = selectedCategories.first?.id ?? Category.allCategoryId
            return (placeholderEntry, categoryId)
        }

        let allIgnored = learningStateManager.ignoredWords
        let allKnown = learningStateManager.knownWords
        var entries = category.entries.filter { !allIgnored.contains($0.id) && !allKnown.contains($0.id) }
        // 1. Before any filtering (initial entries count)
        print("Initial entries count:", entries.count)

        // 3. After applying CEFR filtering
        entries = entries.filter { entry in
            guard let level = entry.level else {
                return self.selectedLanguageLevel == "all"
            }
            return allowedLevels.contains(level)
        }
        print("Entries count after CEFR filtering:", entries.count)

        if let randomEntry = entries.randomElement() {
            return (randomEntry, category.id)
        } else {
            let placeholderEntry = WordEntry(
                id: UUID(),
                word: NSLocalizedString("all_words_completed_title", comment: ""),
                version: -1,
                voiceEntries: nil,
                forms: [],
                translations: ["ru": "Вы прошли все слова", "en": "You've completed all words"],
                level: nil,
                examples: [],
                phoneme: nil
            )
            return (placeholderEntry, category.id)
        }
    }
    
    private func isSwipeUp(_ value: DragGesture.Value) -> Bool {
        value.translation.height < -50
    }
    
    private func isSwipeLeft(_ value: DragGesture.Value) -> Bool {
        value.translation.width < -50
    }
    
    private func isSwipeRight(_ value: DragGesture.Value) -> Bool {
        value.translation.width > 50
    }
    
    private func showWordCard() {
        showCard = true
    }
    
    private func showNextWord() {
 
        if LearningGoalManager.shared.shouldShowGoalAnimation {
            showGoalCelebration = true
            LearningGoalManager.shared.markGoalAnimationShown()
            return
        }
        
        if historyIndex + 1 < history.count {
            historyIndex += 1
            switchToHistoryItem(historyIndex: historyIndex)
        } else if showExamplesAfterWord, !currentEntry.examples.isEmpty {
            proceedToNextExample()
        } else {
            proceedToNextWord()
        }
    }
    
    private func proceedToNextExample() {
        let limit = examplesToShowCount == -1 ? currentEntry.examples.count : min(currentEntry.examples.count, examplesToShowCount)

        if shownExampleIndices.count >= limit || shownExampleIndices.count >= currentEntry.examples.count {
            exampleIndex = nil
            proceedToNextWord()
            return
        }

        let availableIndices = Array(currentEntry.examples.indices).filter { !shownExampleIndices.contains($0) }

        guard let nextIdx = availableIndices.randomElement() else {
            exampleIndex = nil
            proceedToNextWord()
            return
        }

        exampleIndex = nextIdx
        shownExampleIndices.append(nextIdx)
        history = Array(history.prefix(historyIndex + 1)) + [HistoryItem(kind: .example(currentEntry, currentCategoryId, nextIdx))]
        historyIndex += 1

        if playSoundOnWordChange {
            audioPlayerHelper.playExample(entryId: currentEntry.id, exampleIndex: nextIdx + 1)
        }
    }
    
    private func proceedToNextWord() {
        
        if let next = nextPrefetchedEntry, let nextId = nextPrefetchedCategoryId {
            currentEntry = next
            currentCategoryId = nextId
            exampleIndex = nil
            shownExampleIndices = []

            history = Array(history.prefix(historyIndex + 1)) + [HistoryItem(kind: .word(currentEntry, currentCategoryId))]
            historyIndex += 1
            
            LearningGoalManager.shared.incrementProgress()

            if playSoundOnWordChange {
                audioPlayerHelper.playAudio(entryId: currentEntry.id)
            }

            if showExamplesAfterWord, !currentEntry.examples.isEmpty {
                DispatchQueue.global(qos: .utility).async {
                    let limit = examplesToShowCount == -1 ? currentEntry.examples.count : min(currentEntry.examples.count, examplesToShowCount)
                    for index in 0..<limit {
                        audioPlayerHelper.prefetchExample(entryId: currentEntry.id, exampleIndex: index + 1)
                    }
                }
            }

            // Префетчим следующее слово
            DispatchQueue.global(qos: .utility).async {
                let selectedIds = (try? JSONDecoder().decode([UUID].self, from: selectedCategoriesData)) ?? []
                let (prefetchedEntry, prefetchedCategoryId) = pickRandomEntry(wordService: wordService, learningStateManager: learningStateManager, selectedCategoryIds: selectedIds)

                if playSoundOnWordChange {
                    audioPlayerHelper.prefetchAudio(entryId: prefetchedEntry.id)
                }

                DispatchQueue.main.async {
                    nextPrefetchedEntry = prefetchedEntry
                    nextPrefetchedCategoryId = prefetchedCategoryId
                }
            }
        }
    }
    
    private func showPreviousWord() {
        if historyIndex <= 0 { return }
        historyIndex -= 1
        switchToHistoryItem(historyIndex: historyIndex)
    }
    
    private func switchToHistoryItem(historyIndex: Int){
        let item = history[historyIndex]
        print("🔁 Переход к элементу истории #\(historyIndex): \(item)")
        print("📜 Вся история:")
        for (i, h) in history.enumerated() {
            switch h.kind {
            case .word(let e, _):
                print("  [\(i)] word: \(e.word)")
            case .example(let e, _, let idx):
                print("  [\(i)] example[\(idx)]: \(e.examples[idx].text)")
            }
        }
        switch item.kind {
        case .word(let entry, let categoryId):
            currentEntry = entry
            currentCategoryId = categoryId
            exampleIndex = nil
            if playSoundOnWordChange {
                audioPlayerHelper.playAudio(entryId: entry.id)
            }
        case .example(let entry, let categoryId, let idx):
            currentEntry = entry
            currentCategoryId = categoryId
            exampleIndex = idx
            if playSoundOnWordChange {
                let nextIdx = idx + 1
                audioPlayerHelper.playExample(entryId: entry.id, exampleIndex: nextIdx)
            }
        }
    }
    // Resets the word history with a new entry when CEFR level filter changes
    private func resetHistoryWithNewEntry() {
        let selectedIds = (try? JSONDecoder().decode([UUID].self, from: selectedCategoriesData)) ?? []
        let (newEntry, newCategoryId) = pickRandomEntry(wordService: wordService, learningStateManager: learningStateManager, selectedCategoryIds: selectedIds)
        currentEntry = newEntry
        currentCategoryId = newCategoryId
        exampleIndex = nil
        history = [HistoryItem(kind: .word(newEntry, newCategoryId))]
        historyIndex = 0
        if playSoundOnWordChange {
            audioPlayerHelper.playAudio(entryId: newEntry.id)
        }
    }

}

