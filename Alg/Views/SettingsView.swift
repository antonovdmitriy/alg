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
    let audioPlayerHelper: AudioPlayerHelper
    
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @AppStorage("hideLinksToKnownWords") private var hideLinksToKnownWords = false
    @AppStorage("playSoundOnWordChange") private var playSoundOnWordChange = true
    @AppStorage("autoAdvanceAfterAction") private var autoAdvanceAfterAction = true
    @AppStorage("showExamplesAfterWord") private var showExamplesAfterWord = false
    @AppStorage("examplesToShowCount") private var examplesToShowCount = 3
    @State private var showResetConfirmation = false
    @State private var showResetMessage = false

    @AppStorage("showTranslationOnPreview") private var showTranslationOnPreview = false
    var body: some View {
        Form {
            Section(header: Text("settings_translation_section")) {
                NavigationLink(destination: LanguageSelectionView(fromSettings: true)) {
                    HStack {
                        Text("settings_language_label")
                        Spacer()
                        Text(Locale.current.localizedString(forIdentifier: selectedLanguage) ?? selectedLanguage)
                            .foregroundColor(.gray)
                    }
                }
            }
            Section(header: Text("settings_visual_section")) {
                Toggle("settings_solid_color_background", isOn: $visualStyleManager.useSolidColorBackground)
                Toggle("settings_show_translation_on_preview", isOn: $visualStyleManager.showTranslationOnPreview)
            }
            Section(header: Text("settings_my_words_section")) {
                NavigationLink(destination: LearnedWordsView(wordService: wordService, learningStateManager: learningStateManager, audioHelper: audioPlayerHelper)) {
                    Label("settings_learned_words", systemImage: "checkmark")
                }
                NavigationLink(destination: FavoriteWordsView(wordService: wordService, learningStateManager: learningStateManager, audioHelper: audioPlayerHelper)) {
                    Label("settings_favorite_words", systemImage: "star")
                }
                NavigationLink(destination: IgnoredWordsView(wordService: wordService, learningStateManager: learningStateManager, audioHelper: audioPlayerHelper)) {
                    Label("settings_ignored_words", systemImage: "nosign")
                }
            }
            Section(header: Text("settings_learning_section")) {
                NavigationLink(destination: CategorySelectionView(wordService: wordService)) {
                    Text("settings_edit_categories")
                }
                NavigationLink(destination: DailyGoalSelectionView(allowsDismiss: true, onGoalSelected: {})) {
                    Text("settings_edit_daily_goal")
                }
                Toggle("settings_hide_links_to_known_words", isOn: $hideLinksToKnownWords)
                Toggle("settings_play_sound_on_word_change", isOn: $playSoundOnWordChange)
                Toggle("settings_auto_advance_after_action", isOn: $autoAdvanceAfterAction)
                Toggle("settings_show_examples_after_word", isOn: $showExamplesAfterWord)

                if showExamplesAfterWord {
                    NavigationLink(destination: ExamplesCountSelectionView(selectedCount: $examplesToShowCount)) {
                        HStack {
                            Text("settings_examples_to_show_count")
                            Spacer()
                            Text(examplesToShowCount == -1 ? NSLocalizedString("settings_examples_all", comment: "") : "\(examplesToShowCount)")
                                .foregroundColor(.gray)
                        }
                    }
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
    let audioHelper: AudioPlayerHelper
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
            wordService: wordService,
            learningStateManager: learningStateManager,
            audioPlayerHelper: audioHelper
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
    let audioHelper: AudioPlayerHelper
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
            wordService: wordService,
            learningStateManager: learningStateManager,
            audioPlayerHelper: audioHelper
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
    let audioHelper: AudioPlayerHelper
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
            wordService: wordService,
            learningStateManager: learningStateManager,
            audioPlayerHelper: audioHelper
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

struct ExamplesCountSelectionView: View {
    @Binding var selectedCount: Int

    var body: some View {
        List {
            ForEach([-1] + Array(1...10), id: \.self) { number in
                HStack {
                    Text(number == -1 ? NSLocalizedString("settings_examples_all", comment: "") : "\(number)")
                    Spacer()
                    if selectedCount == number {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedCount = number
                }
            }
        }
        .navigationTitle("settings_examples_to_show_count")
    }
}
