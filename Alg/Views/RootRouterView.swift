//
//  RootRouterView.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-29.
//

import SwiftUI

struct RootRouterView: View {
    
    @State private var showSplash = true
    @AppStorage("hasSelectedTranslationLanguage") private var hasSelectedLanguage = false
    @AppStorage("hasSelectedCategories") private var hasSelectedCategories = false
    @AppStorage("hasSelectedDailyGoal") private var hasSelectedDailyGoal = false
    @AppStorage("dailyGoalSelectionShown") private var hasShownDailyGoalSelection = false
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
        } else if !hasSelectedLanguage {
            LanguageSelectionView(showNextButton: true, fromSettings: false)
        } else if !hasSelectedCategories {
            NavigationStack {
                CategorySelectionView(wordService: wordService)
            }
        } else if !hasShownDailyGoalSelection && !hasSelectedDailyGoal {
            DailyGoalSelectionView(mode: .firstLaunch, allowsDismiss: false) {
                hasShownDailyGoalSelection = true
            }
        } else {
            ContentView(wordService: wordService, learningStateManager: learningStateManager, audioPlayerHelper: audioPlayerHelper)
        }
    }
}
