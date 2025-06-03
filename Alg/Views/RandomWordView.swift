import SwiftUI
import AVKit
import AVFoundation

struct RandomWordView: View {
    @Binding var showTabBar: Bool
    private let wordService: WordService
    private let learningStateManager: WordLearningStateManager
    @AppStorage("selectedCategories") private var selectedCategoriesData: Data = Data()
    @AppStorage("dailyGoal") private var dailyGoal: Int = 10
    @State private var currentEntry: WordEntry
    @State private var currentCategoryId: UUID
    @State private var nextPrefetchedEntry: WordEntry?
    @State private var nextPrefetchedCategoryId: UUID?
    @State private var showCard = false
    @State private var entryHistory: [(WordEntry, UUID)] = []
    @State private var lastTapDate = Date.distantPast
    private let tapThreshold: TimeInterval = 0.4
    @State private var feedbackMessage: String?
    @State private var showGoalCelebration = false
    @State private var showGoalVideo = false
    
    init(showTabBar: Binding<Bool>, wordService: WordService, learningStateManager: WordLearningStateManager) {
        self._showTabBar = showTabBar
        self.wordService = wordService
        self.learningStateManager = learningStateManager
        _currentCategoryId = State(initialValue: UUID())
        _currentEntry = State(initialValue: WordEntry(id: UUID(), word: "", forms: [], translations: [:], examples: [], phoneme: nil))
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
                overrideText: .constant(showGoalCelebration ? NSLocalizedString("goal_completed_message", comment: "") : nil)
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
                                    learningStateManager.markKnown(currentEntry.id)
                                    feedbackMessage = NSLocalizedString("marked_as_known", comment: "")
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {}
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    feedbackMessage = nil
                                    showNextWord()
                                }
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.primary)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .shadow(radius: 2)
                            }
                            
                            Button(action: {
                                if !learningStateManager.isIgnored(currentEntry.id) {
                                    learningStateManager.markIgnored(currentEntry.id)
                                    feedbackMessage = NSLocalizedString("marked_as_ignored", comment: "")
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {}
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    feedbackMessage = nil
                                    showNextWord()
                                }
                            }) {
                                Image(systemName: "nosign")
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.primary)
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
                                    showNextWord()
                                }
                            }) {
                                Image(systemName: learningStateManager.isFavorite(currentEntry.id) ? "star.fill" : "star")
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.primary)
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
                        currentEntry = WordEntry(id: UUID(), word: "", forms: [], translations: [:], examples: [], phoneme: nil)
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
                DispatchQueue.global(qos: .utility).async {
                    AudioPlayerHelper.prefetchAudio(categoryId: prefetchedCategoryId.uuidString, entryId: prefetchedEntry.id)
                }
            }
            AudioPlayerHelper.playAudio(categoryId: currentCategoryId.uuidString, entryId: currentEntry.id)
        }
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    guard !showGoalCelebration && !showGoalVideo else { return }
                    if isSwipeUp(value) {
                        showWordCard()
                    } else if isSwipeLeft(value) {
                        showNextWord()
                    } else if isSwipeRight(value), !entryHistory.isEmpty {
                        showPreviousWord()
                    }
                }
        )
        .sheet(isPresented: $showCard) {
            WordCardView(
                entry: currentEntry,
                categoryId: currentCategoryId.uuidString.lowercased(),
                wordService: wordService,
                learningStateManager: learningStateManager
            )
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
        proceedToNextWord()
    }
    
    private func proceedToNextWord() {
        LearningGoalManager.shared.incrementProgress()
        entryHistory.append((currentEntry, currentCategoryId))

        if let next = nextPrefetchedEntry, let nextId = nextPrefetchedCategoryId {
            currentEntry = next
            currentCategoryId = nextId
            print("🔊 Playing audio for word: \(next.word), category ID: \(nextId)")
            AudioPlayerHelper.playAudio(categoryId: nextId.uuidString, entryId: next.id)
        }

        // Prefetch next word asynchronously
        DispatchQueue.global(qos: .utility).async {
            print("🔄 Prefetching next word...")
            let selectedIds = (try? JSONDecoder().decode([UUID].self, from: selectedCategoriesData)) ?? []
            let (prefetchedEntry, prefetchedCategoryId) = Self.pickRandomEntry(wordService: wordService, learningStateManager: learningStateManager, selectedCategoryIds: selectedIds)

            print("🎧 Prefetching audio for: \(prefetchedEntry.word), category ID: \(prefetchedCategoryId)")
            AudioPlayerHelper.prefetchAudio(categoryId: prefetchedCategoryId.uuidString, entryId: prefetchedEntry.id)
            print("✅ Audio prefetch completed (or started) for: \(prefetchedEntry.word)")

            DispatchQueue.main.async {
                print("✅ Prefetched word: \(prefetchedEntry.word), category ID: \(prefetchedCategoryId)")
                nextPrefetchedEntry = prefetchedEntry
                nextPrefetchedCategoryId = prefetchedCategoryId
            }
        }
    }
    
    private func showPreviousWord() {
        withAnimation {
            let previous = entryHistory.removeLast()
            currentEntry = previous.0
            currentCategoryId = previous.1
            AudioPlayerHelper.playAudio(categoryId: currentCategoryId.uuidString, entryId: currentEntry.id)
        }
    }
    

}
