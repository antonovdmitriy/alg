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
        _currentEntry = State(initialValue: WordEntry(id: UUID(), word: "", version: -1, voiceEntries: nil, forms: [], translations: [:], examples: [], phoneme: nil))
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
                        currentEntry = WordEntry(id: UUID(), word: "", version: -1, voiceEntries: nil, forms: [], translations: [:], examples: [], phoneme: nil)
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
                let (randomEntry, randomCategoryId) = Self.pickRandomEntry(wordService: wordService, learningStateManager: learningStateManager, selectedCategoryIds: selectedIds)
                currentEntry = randomEntry
                currentCategoryId = randomCategoryId
                // Prefetch next word
                let (prefetchedEntry, prefetchedCategoryId) = Self.pickRandomEntry(wordService: wordService, learningStateManager: learningStateManager,  selectedCategoryIds: selectedIds)
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
    
    private static func pickRandomEntry(wordService: WordService, learningStateManager: WordLearningStateManager, selectedCategoryIds: [UUID]) -> (WordEntry, UUID) {
        let categories = wordService.allCategories()
        let useAll = selectedCategoryIds.contains(Category.allCategoryId)
        let otherIds = selectedCategoryIds.filter { $0 != Category.allCategoryId }
        
        var categoryChoices: [UUID] = []
        if useAll {
            categoryChoices.append(Category.allCategoryId)
        }
        categoryChoices.append(contentsOf: otherIds)
        
        let chosenCategoryId = categoryChoices.randomElement()!
        
        let chosenCategory: Category
        if chosenCategoryId == Category.allCategoryId {
            chosenCategory = categories.randomElement()!
        } else {
            guard let category = categories.first(where: { $0.id == chosenCategoryId }) else {
                fatalError("Selected category not found.")
            }
            chosenCategory = category
        }
        
        let allIgnored = learningStateManager.ignoredWords
        let allKnown = learningStateManager.knownWords
        let filteredEntries = chosenCategory.entries.filter { !allIgnored.contains($0.id) && !allKnown.contains($0.id) }
        
        if let entry = filteredEntries.randomElement() {
            return (entry, chosenCategory.id)
        } else {
        let placeholderEntry = WordEntry(
            id: UUID(),
            word: NSLocalizedString("all_words_completed_title", comment: ""),
            version: -1,
            voiceEntries: nil,
            forms: [],
            translations: ["ru": "Вы прошли все слова", "en": "You've completed all words"],
            examples: [],
            phoneme: nil
        )
            return (placeholderEntry, chosenCategory.id)
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

        var availableIndices = Array(currentEntry.examples.indices).filter { !shownExampleIndices.contains($0) }

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
                let (prefetchedEntry, prefetchedCategoryId) = Self.pickRandomEntry(wordService: wordService, learningStateManager: learningStateManager, selectedCategoryIds: selectedIds)

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

}
