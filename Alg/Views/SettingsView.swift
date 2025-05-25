//
//  SettingsView.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-17.
//


import SwiftUI

struct SettingsView: View {
    let categories: [Category]
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"

    var body: some View {
        Form {
            Section(header: Text("settings_translation_section")) {
                Picker("settings_language_label", selection: $selectedLanguage) {
                    Text("language_russian").tag("ru")
                    Text("language_english").tag("en")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            Section(header: Text("settings_learning_section")) {
                NavigationLink(destination: DailyGoalSelectionView(allowsDismiss: true, onGoalSelected: {})) {
                    Text("settings_edit_daily_goal")
                }
                NavigationLink(destination: CategorySelectionView(availableCategories: categories)) {
                    Text("settings_edit_categories")
                }
            }
            Section(header: Text("settings_my_words_section")) {
                NavigationLink(destination: LearnedWordsView(categories: categories)) {
                    Label("settings_learned_words", systemImage: "checkmark")
                }
                NavigationLink(destination: FavoriteWordsView(categories: categories)) {
                    Label("settings_favorite_words", systemImage: "star")
                }
                NavigationLink(destination: IgnoredWordsView(categories: categories)) {
                    Label("settings_ignored_words", systemImage: "nosign")
                }
            }
        }
        .navigationTitle("settings_title")
    }
}

struct LearnedWordsView: View {
    let categories: [Category]
    @State private var words: [(WordEntry, UUID)] = []

    var body: some View {
        FilteredWordListView(
            title: NSLocalizedString("settings_learned_words", comment: ""),
            entries: words,
            onDelete: { id in
                var set = WordLearningStateManager.shared.knownWords
                set.remove(id)
                WordLearningStateManager.shared.knownWords = set
                words.removeAll { $0.0.id == id }
            },
            onClear: {
                WordLearningStateManager.shared.knownWords = []
                words = []
            }
        )
        .onAppear {
            words = categories.flatMap { category in
                category.entries
                    .filter { WordLearningStateManager.shared.knownWords.contains($0.id) }
                    .map { ($0, category.id) }
            }
        }
    }
}

struct FavoriteWordsView: View {
    let categories: [Category]
    @State private var words: [(WordEntry, UUID)] = []

    var body: some View {
        FilteredWordListView(
            title: NSLocalizedString("settings_favorite_words", comment: ""),
            entries: words,
            onDelete: { id in
                WordLearningStateManager.shared.toggleFavorite(id)
                words.removeAll { $0.0.id == id }
            },
            onClear: {
                WordLearningStateManager.shared.favoriteWords = []
                words = []
            }
        )
        .onAppear {
            words = categories.flatMap { category in
                category.entries
                    .filter { WordLearningStateManager.shared.favoriteWords.contains($0.id) }
                    .map { ($0, category.id) }
            }
        }
    }
}

struct IgnoredWordsView: View {
    let categories: [Category]
    @State private var words: [(WordEntry, UUID)] = []

    var body: some View {
        FilteredWordListView(
            title: NSLocalizedString("settings_ignored_words", comment: ""),
            entries: words,
            onDelete: { id in
                var set = WordLearningStateManager.shared.ignoredWords
                set.remove(id)
                WordLearningStateManager.shared.ignoredWords = set
                words.removeAll { $0.0.id == id }
            },
            onClear: {
                WordLearningStateManager.shared.ignoredWords = []
                words = []
            }
        )
        .onAppear {
            words = categories.flatMap { category in
                category.entries
                    .filter { WordLearningStateManager.shared.ignoredWords.contains($0.id) }
                    .map { ($0, category.id) }
            }
        }
    }
}
