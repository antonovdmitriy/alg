import SwiftUI

struct RandomWordView: View {
    let categories: [Category]
    @State private var currentEntry: WordEntry
    @State private var currentCategoryId: UUID
    @State private var showCard = false
    @State private var entryHistory: [(WordEntry, UUID)] = []

    init(categories: [Category]) {
        self.categories = categories
        let randomCategory = categories.randomElement()!
        let randomEntry = randomCategory.entries.randomElement()!
        _currentCategoryId = State(initialValue: randomCategory.id)
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
                    if value.translation.height < -50 {
                        showCard = true
                    } else if value.translation.width < -50 {
                        withAnimation {
                            entryHistory.append((currentEntry, currentCategoryId))
                            let newCategory = categories.randomElement()!
                            let newEntry = newCategory.entries.randomElement()!
                            currentEntry = newEntry
                            currentCategoryId = newCategory.id
                            AudioPlayerHelper.playAudio(categoryId: newCategory.id.uuidString, entryId: newEntry.id)
                        }
                    } else if value.translation.width > 50, !entryHistory.isEmpty {
                        withAnimation {
                            let previous = entryHistory.removeLast()
                            currentEntry = previous.0
                            currentCategoryId = previous.1
                            AudioPlayerHelper.playAudio(categoryId: currentCategoryId.uuidString, entryId: currentEntry.id)
                        }
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
}
