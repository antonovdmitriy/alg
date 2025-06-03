//
//  SettingsView.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-17.
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var visualStyleManager: VisualStyleManager
    let wordService: WordService
    let learningStateManager: WordLearningStateManager
    
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @AppStorage("hideLinksToKnownWords") private var hideLinksToKnownWords = true
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
                NavigationLink(destination: CategorySelectionView(wordService: wordService)) {
                    Text("settings_edit_categories")
                }
                NavigationLink(destination: DailyGoalSelectionView(allowsDismiss: true, onGoalSelected: {})) {
                    Text("settings_edit_daily_goal")
                }
                Toggle("settings_hide_links_to_known_words", isOn: $hideLinksToKnownWords)
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
                NavigationLink(destination: LearnedWordsView(wordService: wordService, learningStateManager: learningStateManager)) {
                    Label("settings_learned_words", systemImage: "checkmark")
                }
                NavigationLink(destination: FavoriteWordsView(wordService: wordService, learningStateManager: learningStateManager)) {
                    Label("settings_favorite_words", systemImage: "star")
                }
                NavigationLink(destination: IgnoredWordsView(wordService: wordService, learningStateManager: learningStateManager)) {
                    Label("settings_ignored_words", systemImage: "nosign")
                }
            }
            Section(header: Text("settings_visual_section")) {
                Toggle("settings_solid_color_background", isOn: $visualStyleManager.useSolidColorBackground)
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
    let wordService: WordService
    let learningStateManager: WordLearningStateManager
    @State private var words: [(WordEntry, UUID)] = []

    var body: some View {
        FilteredWordListView(
            title: NSLocalizedString("settings_learned_words", comment: ""),
            entries: words,
            onDelete: { id in
                var set = learningStateManager.knownWords
                set.remove(id)
                learningStateManager.knownWords = set
                words.removeAll { $0.0.id == id }
            },
            onClear: {
                learningStateManager.knownWords = []
                words = []
            },
            wordService: wordService
        )
        .onAppear {
            //TODO: rewrite when there will be index.
            words = wordService.allWords().compactMap { entry in
                let id = entry.id
                return learningStateManager.knownWords.contains(id) ? (entry, id) : nil
            }
        }
    }
}

struct FavoriteWordsView: View {
    let wordService: WordService
    let learningStateManager: WordLearningStateManager
    @State private var words: [(WordEntry, UUID)] = []

    var body: some View {
        FilteredWordListView(
            title: NSLocalizedString("settings_favorite_words", comment: ""),
            entries: words,
            onDelete: { id in
                learningStateManager.toggleFavorite(id)
                words.removeAll { $0.0.id == id }
            },
            onClear: {
                learningStateManager.favoriteWords = []
                words = []
            },
            wordService: wordService
        )
        .onAppear {
            //TODO: rewrite when there will be index.
            words = wordService.allWords().compactMap { entry in
                let id = entry.id
                return learningStateManager.favoriteWords.contains(id) ? (entry, id) : nil
            }
        }
    }
}

struct IgnoredWordsView: View {
    let wordService: WordService
    let learningStateManager: WordLearningStateManager
    @State private var words: [(WordEntry, UUID)] = []

    var body: some View {
        FilteredWordListView(
            title: NSLocalizedString("settings_ignored_words", comment: ""),
            entries: words,
            onDelete: { id in
                var set = learningStateManager.ignoredWords
                set.remove(id)
                learningStateManager.ignoredWords = set
                words.removeAll { $0.0.id == id }
            },
            onClear: {
                learningStateManager.ignoredWords = []
                words = []
            },
            wordService: wordService
        )
        .onAppear {
            //TODO: rewrite when there will be index.
            words = wordService.allWords().compactMap { entry in
                let id = entry.id
                return learningStateManager.ignoredWords.contains(id) ? (entry, id) : nil
            }
        }
    }
}
