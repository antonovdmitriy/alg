//
//  FilteredWordListView.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-25.
//


import SwiftUI
import Foundation

enum WordListType {
    case favorite
    case known
    case ignored
}

struct FilteredWordListView: View {
    let title: String
    let allEntries: [WordEntry]
    let type: WordListType
    let categoryIdProvider: (UUID) -> String

    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @State private var refreshTrigger = false

    var body: some View {
        let words: [WordEntry] = {
            _ = refreshTrigger // чтобы зависеть от состояния
            let ids: Set<UUID>
            switch type {
            case .favorite:
                ids = WordLearningStateManager.shared.favoriteWords
            case .known:
                ids = WordLearningStateManager.shared.knownWords
            case .ignored:
                ids = WordLearningStateManager.shared.ignoredWords
            }
            return allEntries.filter { ids.contains($0.id) }
        }()

        let onDelete: (UUID) -> Void = { id in
            switch type {
            case .favorite:
                WordLearningStateManager.shared.toggleFavorite(id)
            case .known:
                var set = WordLearningStateManager.shared.knownWords
                set.remove(id)
                WordLearningStateManager.shared.knownWords = set
            case .ignored:
                var set = WordLearningStateManager.shared.ignoredWords
                set.remove(id)
                WordLearningStateManager.shared.ignoredWords = set
            }
        }

        let onClear: () -> Void = {
            switch type {
            case .favorite:
                WordLearningStateManager.shared.favoriteWords = []
            case .known:
                WordLearningStateManager.shared.knownWords = []
            case .ignored:
                WordLearningStateManager.shared.ignoredWords = []
            }
            refreshTrigger.toggle()
        }

        VStack {
            if words.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 48))
                        .foregroundColor(.green.opacity(0.7))
                    Text("Список пуст")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(words) { entry in
                        NavigationLink(destination: WordDetailView(entry: entry, categoryId: categoryIdProvider(entry.id))) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.word)
                                    .font(.headline)
                                if let translation = entry.translations[selectedLanguage] {
                                    Text(translation)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            onDelete(words[index].id)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(title)
        .toolbar {
            if !words.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Очистить") {
                        onClear()
                    }
                }
            }
        }
    }
}
