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
    @AppStorage("selectedCategories") private var selectedCategoriesData: Data = Data()
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    
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
            while pairs.count < 9, let entry = availableWords.popLast() {
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

            while pairs.count < 9, let entry = availableWords.popLast() {
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

struct MatchingGameView: View {
    @Binding var showTabBar: Bool
    @State private var lastTapDate: Date = .distantPast
    private let tapThreshold: TimeInterval = 0.4

    let wordService: WordService
    let learningStateManager: WordLearningStateManager

    @StateObject private var viewModel: MatchingGameViewModel
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"

    @AppStorage("selectedCategories") private var selectedCategoriesData: Data = Data()
    @EnvironmentObject var visualStyleManager: VisualStyleManager
    
    init(showTabBar: Binding<Bool>, wordService: WordService, learningStateManager: WordLearningStateManager) {
        self._showTabBar = showTabBar
        _viewModel = StateObject(wrappedValue: MatchingGameViewModel(wordService: wordService, learningStateManager: learningStateManager))
        self.wordService = wordService
        self.learningStateManager = learningStateManager
    }

    var body: some View {
        ZStack {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                if visualStyleManager.useSolidColorBackground {
                    AnimatedColorBackground(palettes: [
                        [Color(red: 0.1, green: 0.15, blue: 0.25)],
                        [Color(red: 0.05, green: 0.2, blue: 0.15)],
                        [Color(red: 0.2, green: 0.1, blue: 0.3)],
                        [Color(red: 0.1, green: 0.05, blue: 0.2)],
                        [Color(red: 0.15, green: 0.1, blue: 0.2)],
                        [Color(red: 0.1, green: 0.15, blue: 0.1)],
                        [Color(red: 0.1, green: 0.1, blue: 0.2)],
                        [Color(red: 0.12, green: 0.1, blue: 0.25)],
                        [Color(red: 0.1, green: 0.2, blue: 0.3)],
                        [Color(red: 0.08, green: 0.1, blue: 0.15)],
                        [Color(red: 0.05, green: 0.1, blue: 0.2)],
                        [Color(red: 0.2, green: 0.15, blue: 0.25)],
                        [Color(red: 0.15, green: 0.15, blue: 0.15)],
                    ])
                } else {
                    AnimatedGradientBackground(palettes: [
                        [Color.black, Color.cyan, Color.indigo],
                        [Color.black, Color.orange, Color.purple, Color.blue],
                        [Color.black, Color.blue, Color.mint],
                        [Color.black, Color.cyan, Color.green],
                        [Color.black, Color.mint, Color.yellow],
                        [Color.black, Color.indigo, Color.teal],
                        [Color.black, Color.blue, Color.pink],
                        [Color.black, Color.orange, Color.mint],
                        [Color.black, Color.purple, Color.cyan],
                        [Color.black, Color.green.opacity(0.6), Color.blue.opacity(0.7), Color.purple.opacity(0.8)],
                        [Color.black, Color.indigo, Color.purple, Color.red.opacity(0.6)],
                        [Color.black, Color.cyan, Color.mint, Color.white.opacity(0.3)],
                        [Color.black, Color.pink.opacity(0.5), Color.purple.opacity(0.5), Color.teal.opacity(0.6)],
                    ])
                }
            } else {
                if visualStyleManager.useSolidColorBackground {
                    AnimatedColorBackground(palettes: [
                        [Color(red: 1.0, green: 0.9, blue: 0.85)],
                        [Color(red: 0.9, green: 0.95, blue: 0.8)],
                        [Color(red: 0.85, green: 0.95, blue: 1.0)],
                        [Color(red: 0.9, green: 1.0, blue: 0.9)],
                        [Color(red: 0.95, green: 0.85, blue: 0.8)],
                        [Color(red: 0.9, green: 0.9, blue: 1.0)],
                        [Color(red: 1.0, green: 0.85, blue: 0.95)],
                        [Color(red: 0.95, green: 0.9, blue: 1.0)],
                        [Color(red: 0.9, green: 1.0, blue: 1.0)],
                        [Color(red: 0.85, green: 0.9, blue: 0.95)],
                    ])
                } else {
                    AnimatedGradientBackground(palettes: [
                        [.pink, .orange, .yellow],
                        [.mint, .teal, .blue],
                        [.cyan, .indigo, .purple],
                        [.green, .mint],
                        [.orange, .red],
                        [.yellow, .green, .blue],
                        [.teal, .cyan],
                        [.purple, .pink, .mint],
                        [.blue, .indigo, .teal],
                        [.orange, .yellow, .mint],
                        [.red, .orange, .pink],
                        [.blue, .purple, .mint],
                        [.mint, .teal, .pink],
                        [.cyan, .green, .yellow],
                        [.orange, .mint, .blue],
                        [.purple, .cyan, .mint],
                        [.indigo, .purple, .red],
                        [.yellow, .cyan, .pink],
                        [.green, .blue, .mint],
                        [.pink, .yellow],
                        [.mint, .green, .yellow],
                        [.indigo, .purple],
                        [.cyan, .blue],
                        [.yellow, .mint, .green],
                        [.teal, .blue],
                        [.green, .cyan],
                        [.indigo, .mint, .teal],
                        [.orange, .indigo],
                        [.cyan, .pink, .mint],
                        [.green, .blue, .mint],
                        [.pink, .purple, .yellow]
                    ])
                }
            }

            HStack( alignment: .top, spacing: 30) {
                VStack(spacing: 12) {
                    ForEach(viewModel.leftColumn) { pair in
                        if !pair.isMatched {
                            let isSelected = viewModel.selectedLeft?.id == pair.id
                            let isLight = UITraitCollection.current.userInterfaceStyle == .light
                            let useGradient = !visualStyleManager.useSolidColorBackground
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .contentShape(Rectangle())
                                Text(pair.left)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .minimumScaleFactor(0.5)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        (UITraitCollection.current.userInterfaceStyle == .light && visualStyleManager.useSolidColorBackground)
                                            ? Color.clear
                                            : (UITraitCollection.current.userInterfaceStyle == .dark && visualStyleManager.useSolidColorBackground)
                                                ? Color.clear
                                                : isSelected && isLight && !visualStyleManager.useSolidColorBackground
                                                    ? Color.accentColor.opacity(0.2)
                                                    : Color(UIColor {
                                                        $0.userInterfaceStyle == .dark
                                                            ? UIColor.systemGray5
                                                            : UIColor.systemGray6
                                                    })
                                    )
                            )
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                            .overlay(
                                Group {
                                    if UITraitCollection.current.userInterfaceStyle == .dark && visualStyleManager.useSolidColorBackground {
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(
                                                isSelected ? Color.white : Color.white.opacity(0.25),
                                                lineWidth: 2
                                            )
                                    } else if UITraitCollection.current.userInterfaceStyle == .light && visualStyleManager.useSolidColorBackground {
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(
                                                isSelected ? Color.primary : Color.primary.opacity(0.25),
                                                lineWidth: 1
                                            )
                                    } else if !(isLight && !visualStyleManager.useSolidColorBackground) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(
                                                isSelected
                                                    ? Color.accentColor.opacity(UITraitCollection.current.userInterfaceStyle == .dark ? 1 : 0.4)
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    }
                                }
                            )
                            .shadow(color:
                                (isSelected && UITraitCollection.current.userInterfaceStyle == .dark)
                                    ? Color.accentColor.opacity(0.4)
                                    : Color.clear,
                                radius: (isSelected && UITraitCollection.current.userInterfaceStyle == .dark) ? 6 : 0,
                                x: 0, y: 0
                            )
                            .transition(.scale.combined(with: .opacity))
                            .onTapGesture {
                                viewModel.select(pair: pair, isLeft: true)
                            }
                        }
                    }
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.rightColumn) { pair in
                        if !pair.isMatched {
                            let isSelected = viewModel.selectedRight?.id == pair.id
                            let isLight = UITraitCollection.current.userInterfaceStyle == .light
                            let useGradient = !visualStyleManager.useSolidColorBackground
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .contentShape(Rectangle())
                                Text(pair.right)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .minimumScaleFactor(0.5)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        (UITraitCollection.current.userInterfaceStyle == .light && visualStyleManager.useSolidColorBackground)
                                            ? Color.clear
                                            : (UITraitCollection.current.userInterfaceStyle == .dark && visualStyleManager.useSolidColorBackground)
                                                ? Color.clear
                                                : isSelected && isLight && !visualStyleManager.useSolidColorBackground
                                                    ? Color.accentColor.opacity(0.2)
                                                    : Color(UIColor {
                                                        $0.userInterfaceStyle == .dark
                                                            ? UIColor.systemGray5
                                                            : UIColor.systemGray6
                                                    })
                                    )
                            )
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                            .overlay(
                                Group {
                                    if UITraitCollection.current.userInterfaceStyle == .dark && visualStyleManager.useSolidColorBackground {
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(
                                                isSelected ? Color.white : Color.white.opacity(0.25),
                                                lineWidth: 2
                                            )
                                    } else if UITraitCollection.current.userInterfaceStyle == .light && visualStyleManager.useSolidColorBackground {
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(
                                                isSelected ? Color.primary : Color.primary.opacity(0.25),
                                                lineWidth: 1
                                            )
                                    } else if !(isLight && !visualStyleManager.useSolidColorBackground) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(
                                                isSelected
                                                    ? Color.accentColor.opacity(UITraitCollection.current.userInterfaceStyle == .dark ? 1 : 0.4)
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    }
                                }
                            )
                            .shadow(color:
                                (isSelected && UITraitCollection.current.userInterfaceStyle == .dark)
                                    ? Color.accentColor.opacity(0.4)
                                    : Color.clear,
                                radius: (isSelected && UITraitCollection.current.userInterfaceStyle == .dark) ? 6 : 0,
                                x: 0, y: 0
                            )
                            .transition(.scale.combined(with: .opacity))
                            .onTapGesture {
                                viewModel.select(pair: pair, isLeft: false)
                            }
                        }
                    }
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.25), value: viewModel.pairs)
            .onChange(of: selectedLanguage) { _ in
                viewModel.generatePairs(preserveIds: true)
            }
            .onChange(of: selectedCategoriesData) { _ in
                viewModel.generatePairs(preserveIds: true)
            }
        }
        .onTapGesture {
            let now = Date()
            if now.timeIntervalSince(lastTapDate) > tapThreshold {
                lastTapDate = now
                withAnimation {
                    showTabBar.toggle()
                }
            }
        }
        .toolbar(showTabBar ? .visible : .hidden, for: .tabBar)
    }
}
