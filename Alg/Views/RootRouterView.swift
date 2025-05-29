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
    
    init(wordService: WordService) {
        self.wordService = wordService
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
            ContentView(wordService: wordService)
        }
    }
}
