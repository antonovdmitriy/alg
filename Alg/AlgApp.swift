//
//  AlgApp.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-14.
//

import SwiftUI
import AVKit

@main
struct AlgApp: App {
    @State private var showSplash = true
    @State private var selectedSplash: String? = nil
    @AppStorage("hasSelectedTranslationLanguage") private var hasSelectedLanguage = false
    @AppStorage("hasSelectedCategories") private var hasSelectedCategories = false
    @AppStorage("hasSelectedDailyGoal") private var hasSelectedDailyGoal = false
    @AppStorage("lastSplashIndex") private var lastSplashIndex: Int = -1
    @State private var categories: [Category] = []
    
    // Set this to the duration of alg_intro.mp4 in seconds, e.g., 2.5 if the video is 2.5 seconds long
    private let splashScreenDelay: TimeInterval = 5

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
        Group {
            if let splash = selectedSplash {
                FullScreenVideoPlayer(player: AVPlayer(url: Bundle.main.url(forResource: splash, withExtension: "mp4")!))
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear {
            if selectedSplash == nil {
                let splashVideos = ["splash_2", "splash_3"]
                let nextIndex = (lastSplashIndex + 1) % splashVideos.count
                print("Last splash index: \(lastSplashIndex)")
                print("Next splash index: \(nextIndex)")
                lastSplashIndex = nextIndex
                selectedSplash = splashVideos[nextIndex]
                print("Selected splash: \(selectedSplash!)")
            }
            loadAppDataIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + splashScreenDelay) {
                withAnimation {
                    showSplash = false
                }
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
