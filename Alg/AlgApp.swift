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
    @State private var categories: [Category]? = nil

    var body: some Scene {
        WindowGroup {
            if showSplash || categories == nil {
                LaunchSplashView()
                    .onAppear {
                        if categories == nil {
                            DispatchQueue.global().async {
                                let loaded = DataLoader.loadCategories()
                                DispatchQueue.main.async {
                                    self.categories = loaded
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        withAnimation {
                                            showSplash = false
                                        }
                                    }
                                }
                            }
                        }
                    }
            } else if !hasSelectedLanguage {
                LanguageSelectionView()
            } else if !hasSelectedCategories {
                CategorySelectionView(availableCategories: categories!)
            } else {
                ContentView(categories: categories!)
            }
        }
    }
}
