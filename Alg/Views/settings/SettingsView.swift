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
    @State private var showDeleteGoalMessage = false

    @AppStorage("showTranslationOnPreview") private var showTranslationOnPreview = false
    @AppStorage("selectedLanguageLevel") private var selectedLanguageLevel = "all"
    @AppStorage("includeLowerLevels") private var includeLowerLevels = true

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
            Section(header: Text("settings_language_level_section")) {
                NavigationLink(destination: LanguageLevelSettingsView()) {
                    HStack {
                        Text("settings_language_level_label")
                        Spacer()
                        Text(selectedLanguageLevel.uppercased())
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
                NavigationLink(destination: DailyGoalSelectionView(mode: .settings, onGoalSelected: {})) {
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
            Section {
                Button {
                    if let url = URL(string: "https://apps.apple.com/app/id6746169818?action=write-review") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label {
                        Text("leave_review").foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "heart")
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didDeleteDailyGoal)) { _ in
            withAnimation {
                showDeleteGoalMessage = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showDeleteGoalMessage = false
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
                if showDeleteGoalMessage {
                    Text(NSLocalizedString("daily_goal_deleted_success", comment: ""))
                        .font(.subheadline)
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.primary)
                        .transition(.opacity)
                }
            }
            .padding(),
            alignment: .bottom
        )
    }
}
