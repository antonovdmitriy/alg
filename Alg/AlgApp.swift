//
//  AlgApp.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-14.
//

import SwiftUI

@main
struct AlgApp: App {
    @State private var showSplash = true
    @AppStorage("hasSelectedTranslationLanguage") private var hasSelectedLanguage = false
    @AppStorage("hasSelectedCategories") private var hasSelectedCategories = false
    @AppStorage("hasSelectedDailyGoal") private var hasSelectedDailyGoal = false
    @State private var categories: [Category] = []
    
    private let splashScreenDelay: TimeInterval = 2

    private func loadAppData() {
        DispatchQueue.global().async {
            let loaded = DataLoader.loadCategories()
            DispatchQueue.main.async {
                self.categories = loaded
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + splashScreenDelay) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
    
    private func loadAppDataIfNeeded() {
        guard categories.isEmpty else { return }
        loadAppData()
    }
    
    private var splashView: some View {
        LaunchSplashView()
            .onAppear {
                DispatchQueue.main.async {
                    loadAppDataIfNeeded()
                }
            }
    }
    
    @ViewBuilder
    private var rootView: some View {
        if showSplash || categories.isEmpty {
            splashView
        } else if !hasSelectedLanguage {
            LanguageSelectionView()
        } else if !hasSelectedCategories {
            CategorySelectionView(availableCategories: categories)
        } else if !hasSelectedDailyGoal {
            DailyGoalSelectionView(allowsDismiss: false) {
                hasSelectedDailyGoal = true
            }
        } else {
            ContentView(categories: categories)
        }
    }

    var body: some Scene {
        WindowGroup {
            rootView
        }
    }
}
