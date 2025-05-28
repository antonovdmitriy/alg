import SwiftUI
import AVKit
import AVFoundation

struct RandomWordView: View {
    @Binding var showTabBar: Bool
    let categories: [Category]
    @AppStorage("selectedCategories") private var selectedCategoriesData: Data = Data()
    @AppStorage("dailyGoal") private var dailyGoal: Int = 10
    @State private var currentEntry: WordEntry
    @State private var currentCategoryId: UUID
    @State private var showCard = false
    @State private var entryHistory: [(WordEntry, UUID)] = []
    @State private var lastTapDate = Date.distantPast
    private let tapThreshold: TimeInterval = 0.4
    @State private var feedbackMessage: String?
    @State private var showGoalCelebration = false
    @State private var showGoalVideo = false
    
    init(categories: [Category], showTabBar: Binding<Bool>) {
        self.categories = categories
        self._showTabBar = showTabBar
        _currentCategoryId = State(initialValue: UUID())
        _currentEntry = State(initialValue: WordEntry(id: UUID(), word: "", forms: [], translations: [:], examples: []))
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
            
            if showTabBar && !showGoalVideo {
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
                                if !WordLearningStateManager.shared.isKnown(currentEntry.id) {
                                    WordLearningStateManager.shared.markKnown(currentEntry.id)
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
                                if !WordLearningStateManager.shared.isIgnored(currentEntry.id) {
                                    WordLearningStateManager.shared.markIgnored(currentEntry.id)
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
                                let isAlreadyFavorite = WordLearningStateManager.shared.isFavorite(currentEntry.id)
                                WordLearningStateManager.shared.toggleFavorite(currentEntry.id)
                                feedbackMessage = isAlreadyFavorite ? NSLocalizedString("removed_from_favorites", comment: "") : NSLocalizedString("added_to_favorites", comment: "")
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {}
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    feedbackMessage = nil
                                    showNextWord()
                                }
                            }) {
                                Image(systemName: WordLearningStateManager.shared.isFavorite(currentEntry.id) ? "star.fill" : "star")
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
            
            if showTabBar && dailyGoal > 0 && !showGoalVideo {
                VStack {
                    Spacer()
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            let progressFraction = max(min(CGFloat(LearningGoalManager.shared.learnedToday) / CGFloat(max(dailyGoal, 1)), 1.0), 0.0)
                            let allColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
                            let colorCount = max(Int(round(progressFraction * CGFloat(allColors.count))), 1)
                            let visibleColors = Array(allColors.prefix(colorCount))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: visibleColors),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(
                                    width: progressFraction * geometry.size.width,
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 0)
                }
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
                        currentEntry = WordEntry(id: UUID(), word: "", forms: [], translations: [:], examples: [])
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
                let (randomEntry, randomCategoryId) = Self.pickRandomEntry(from: categories, selectedCategoryIds: selectedIds)
                currentEntry = randomEntry
                currentCategoryId = randomCategoryId
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
            WordCardView(entry: currentEntry, categoryId: currentCategoryId.uuidString.lowercased(), onClose: {
                showCard = false
            })
        }
        .toolbar(showTabBar ? .visible : .hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private static func pickRandomEntry(from categories: [Category], selectedCategoryIds: [UUID]) -> (WordEntry, UUID) {
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
        
        let allIgnored = WordLearningStateManager.shared.ignoredWords
        let allKnown = WordLearningStateManager.shared.knownWords
        let filteredEntries = chosenCategory.entries.filter { !allIgnored.contains($0.id) && !allKnown.contains($0.id) }
        
        if let entry = filteredEntries.randomElement() {
            return (entry, chosenCategory.id)
        } else {
            let placeholderEntry = WordEntry(
                id: UUID(),
                word: NSLocalizedString("all_words_completed_title", comment: ""),
                forms: [],
                translations: ["ru": "Вы прошли все слова", "en": "You've completed all words"],
                examples: []
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
        let selectedIds = (try? JSONDecoder().decode([UUID].self, from: selectedCategoriesData)) ?? []
        let (newEntry, newCategoryId) = Self.pickRandomEntry(from: categories, selectedCategoryIds: selectedIds)
        currentEntry = newEntry
        currentCategoryId = newCategoryId
        AudioPlayerHelper.playAudio(categoryId: newCategoryId.uuidString, entryId: newEntry.id)
        DispatchQueue.global(qos: .utility).async {
            let (nextEntry, nextCatId) = Self.pickRandomEntry(from: categories, selectedCategoryIds: selectedIds)
            AudioPlayerHelper.prefetchAudio(categoryId: nextCatId.uuidString, entryId: nextEntry.id)
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
