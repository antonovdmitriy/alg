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
            LanguageSelectionView()
        } else if !hasSelectedCategories {
            CategorySelectionView(wordService: wordService)
        } else if !hasSelectedDailyGoal {
            DailyGoalSelectionView(allowsDismiss: false) {
                hasSelectedDailyGoal = true
            }
        } else {
            ContentView(wordService: wordService, learningStateManager: learningStateManager, audioPlayerHelper: audioPlayerHelper)
        }
    }
}
