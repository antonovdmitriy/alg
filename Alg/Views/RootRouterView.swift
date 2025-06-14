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
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
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

struct OnboardingIntroView: View {
    @State private var currentPage = 0
    let onFinish: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private var gradientColorsForTheme: [[Color]] {
        return [
            [Color.blue, Color.purple],
            [Color.indigo, Color.teal],
            [Color.pink, Color.orange]
        ]
    }

    private let icons: [String] = [
        "leaf.fill",
        "slider.horizontal.3",
        "book.fill"
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: gradientColorsForTheme[currentPage % gradientColorsForTheme.count]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TabView(selection: $currentPage) {
                onboardingPage(
                    title: "Добро пожаловать",
                    text: "Это спокойное место, где ты учишь шведский язык в своём ритме.\nБез давления. Без оценок. Только слова и примеры.",
                    tag: 0
                )
                onboardingPage(
                    title: "Настраивай как хочешь",
                    text: "Выбирай цель, категории — или просто начни с одного слова. Всё настраивается под тебя.",
                    tag: 1
                )
                onboardingPage(
                    title: "Готов начать?",
                    text: "Слушай, читай, выбирай — как тебе удобно.\nГотов начать?",
                    tag: 2,
                    isLast: true
                )
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
    }

    private func onboardingPage(title: String, text: String, tag: Int, isLast: Bool = false) -> some View {
        let textColor = Color.white

        return ZStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: icons[tag % icons.count])
                    .font(.system(size: 64))
                    .foregroundColor(textColor)
                    .padding(.bottom, 12)
                    .scaleEffect(currentPage == tag ? 1.1 : 1.0)
                    .animation(.easeOut(duration: 0.3), value: currentPage)
                Text(title)
                    .font(colorScheme == .dark ? .largeTitle.bold() : .title2.weight(.regular))
                    .foregroundColor(textColor)
                Text(text)
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
                    .padding(.horizontal)
                Spacer()
                if isLast {
                    Button("Продолжить") {
                        onFinish()
                    }
                    .font(.headline)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3))
                    )
                    .foregroundColor(textColor)
                    .cornerRadius(12)
                }
                Spacer().frame(height: 40)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .tag(tag)
    }
}
