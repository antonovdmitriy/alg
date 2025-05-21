import SwiftUI

struct RandomWordView: View {
    let categories: [Category]
    @State private var currentEntry: WordEntry
    @State private var currentCategoryId: UUID
    @State private var showCard = false
    @State private var entryHistory: [(WordEntry, UUID)] = []

    init(categories: [Category]) {
        self.categories = categories
        let (randomEntry, randomCategoryId) = Self.pickRandomEntry(from: categories)
        _currentCategoryId = State(initialValue: randomCategoryId)
        _currentEntry = State(initialValue: randomEntry)
    }

    var body: some View {
        ZStack {
            WordPreviewView(entry: currentEntry, categoryId: currentCategoryId.uuidString.lowercased())
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
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
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private static func pickRandomEntry(from categories: [Category]) -> (WordEntry, UUID) {
        let allEntriesWithCategory = categories.flatMap { category in
            category.entries.map { entry in (entry, category.id) }
        }
        return allEntriesWithCategory.randomElement()!
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
            let (newEntry, newCategoryId) = Self.pickRandomEntry(from: categories)
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
