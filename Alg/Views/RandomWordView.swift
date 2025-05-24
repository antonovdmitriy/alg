import SwiftUI

struct RandomWordView: View {
    @Binding var showTabBar: Bool
    let categories: [Category]
    @AppStorage("selectedCategories") private var selectedCategoriesData: Data = Data()
    @State private var currentEntry: WordEntry
    @State private var currentCategoryId: UUID
    @State private var showCard = false
    @State private var entryHistory: [(WordEntry, UUID)] = []
    @State private var lastTapDate = Date.distantPast
    private let tapThreshold: TimeInterval = 0.4

    private var favoriteWords: Set<UUID> {
        let stored = UserDefaults.standard.data(forKey: "favoriteWords")
        return (try? JSONDecoder().decode([UUID].self, from: stored ?? Data())).map(Set.init) ?? []
    }

    private func toggleFavorite(for id: UUID) {
        var favorites = favoriteWords
        if favorites.contains(id) {
            favorites.remove(id)
        } else {
            favorites.insert(id)
        }
        if let data = try? JSONEncoder().encode(Array(favorites)) {
            UserDefaults.standard.set(data, forKey: "favoriteWords")
        }
    }

    init(categories: [Category], showTabBar: Binding<Bool>) {
        self.categories = categories
        self._showTabBar = showTabBar
        _currentCategoryId = State(initialValue: UUID())
        _currentEntry = State(initialValue: WordEntry(id: UUID(), word: "", forms: [], translations: [:], examples: []))
    }

    var body: some View {
        ZStack {
            WordPreviewView(entry: currentEntry, categoryId: currentCategoryId.uuidString.lowercased())
                .edgesIgnoringSafeArea(.all)

            Image(systemName: "chevron.compact.up")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 20)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
            
            if showTabBar {
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Button(action: {
                                var known = (try? JSONDecoder().decode([UUID].self, from: UserDefaults.standard.data(forKey: "knownWords") ?? Data())) ?? []
                                if !known.contains(currentEntry.id) {
                                    known.append(currentEntry.id)
                                    if let data = try? JSONEncoder().encode(known) {
                                        UserDefaults.standard.set(data, forKey: "knownWords")
                                    }
                                }
                                showNextWord()
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.primary)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .shadow(radius: 2)
                            }

                            Button(action: {
                                var ignored = (try? JSONDecoder().decode([UUID].self, from: UserDefaults.standard.data(forKey: "ignoredWords") ?? Data())) ?? []
                                if !ignored.contains(currentEntry.id) {
                                    ignored.append(currentEntry.id)
                                    if let data = try? JSONEncoder().encode(ignored) {
                                        UserDefaults.standard.set(data, forKey: "ignoredWords")
                                    }
                                }
                                showNextWord()
                            }) {
                                Image(systemName: "nosign")
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.primary)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .shadow(radius: 2)
                            }

                            Button(action: {
                                toggleFavorite(for: currentEntry.id)
                                showNextWord()
                            }) {
                                Image(systemName: favoriteWords.contains(currentEntry.id) ? "star.fill" : "star")
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

        let entry = chosenCategory.entries.randomElement()!
        return (entry, chosenCategory.id)
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
        withAnimation {
            entryHistory.append((currentEntry, currentCategoryId))
            let selectedIds = (try? JSONDecoder().decode([UUID].self, from: selectedCategoriesData)) ?? []
            let (newEntry, newCategoryId) = Self.pickRandomEntry(from: categories, selectedCategoryIds: selectedIds)
            currentEntry = newEntry
            currentCategoryId = newCategoryId
            AudioPlayerHelper.playAudio(categoryId: newCategoryId.uuidString, entryId: newEntry.id)
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
