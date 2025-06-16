import SwiftUI

struct RootRouterView: View {
    
    @State private var showSplash = true
    @AppStorage("hasSelectedTranslationLanguage") private var hasSelectedLanguage = false
    @AppStorage("hasSelectedCategories") private var hasSelectedCategories = false
    @AppStorage("hasSelectedDailyGoal") private var hasSelectedDailyGoal = false
    @AppStorage("dailyGoalSelectionShown") private var hasShownDailyGoalSelection = false
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @AppStorage("hasShownLanguageLevelSelection") private var hasShownLanguageLevelSelection = false
    
    
    let wordService: WordService
    let learningStateManager: WordLearningStateManager
    let audioPlayerHelper: AudioPlayerHelper
    
    init(wordService: WordService, learningStateManager: WordLearningStateManager, audioPlayerHelper: AudioPlayerHelper) {
        self.wordService = wordService
        self.learningStateManager = learningStateManager
        self.audioPlayerHelper = audioPlayerHelper
    }
    
    var body: some View {
        if showSplash || wordService.allCategories().isEmpty {
            SplashView(showSplash: $showSplash)
        } else if !hasSeenIntro {
            OnboardingIntroView(onFinish: {
                hasSeenIntro = true
            })
        } else if !hasSelectedLanguage {
            LanguageSelectionView(showNextButton: true, fromSettings: false)
        } else if !hasShownLanguageLevelSelection {
            NavigationView {
                LanguageLevelSettingsView(fromSettings: false, onFinish: {
                    hasShownLanguageLevelSelection = true
                })
                .navigationBarTitleDisplayMode(.inline)
            }
        } else if !hasSelectedCategories {
            NavigationStack {
                CategorySelectionView(wordService: wordService)
            }
        } else if !hasShownDailyGoalSelection && !hasSelectedDailyGoal {
            NavigationView {
                DailyGoalSelectionView(mode: .firstLaunch, allowsDismiss: false) {
                    hasShownDailyGoalSelection = true
                }
            }
        } else {
            ContentView(wordService: wordService, learningStateManager: learningStateManager, audioPlayerHelper: audioPlayerHelper)
        }
    }
}
