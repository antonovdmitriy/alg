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
    @State private var showResetConfirmation = false
    @State private var showResetMessage = false

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
                Label("settings_reset_daily_progress", systemImage: "arrow.counterclockwise")
                    .onTapGesture {
                        showResetConfirmation = true
                    }
                    .alert(isPresented: $showResetConfirmation) {
                        Alert(
                            title: Text("reset_daily_progress_title"),
                            message: Text("reset_daily_progress_message"),
                            primaryButton: .destructive(Text("reset_daily_progress_confirm")) {
                                LearningGoalManager.shared.resetDailyProgress()
                                showResetMessage = true
                            },
                            secondaryButton: .cancel(Text("reset_daily_progress_cancel"))
                        )
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
        .overlay(
            Group {
                if showResetMessage {
                    Text(NSLocalizedString("daily_progress_reset_success", comment: ""))
                        .font(.subheadline)
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.primary)
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    showResetMessage = false
                                }
                            }
                        }
                }
            }
            .padding(),
            alignment: .bottom
        )
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
