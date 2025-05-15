import SwiftUI

struct RandomWordView: View {
    let categories: [Category]
    let allEntries: [WordEntry]
    @State private var currentEntry: WordEntry

    init(categories: [Category]) {
        self.categories = categories
        self.allEntries = categories.flatMap { $0.entries }
        _currentEntry = State(initialValue: categories.flatMap { $0.entries }.randomElement() ?? WordEntry(
            id: UUID(),
            word: "–",
            translation: "–",
            examples: []
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let category = categoryFor(entry: currentEntry) {
                        WordCardView(entry: currentEntry, categoryId: category.id.uuidString)
                    } else {
                        Text("category_not_found")
                    }
                }
                .padding()
            }

            Divider()

            Button(action: {
                if let newWord = allEntries.randomElement() {
                    currentEntry = newWord
                }
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("next_random_word")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle(Text("random_word_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    func categoryFor(entry: WordEntry) -> Category? {
        categories.first { $0.entries.contains(where: { $0.id == entry.id }) }
    }
}
