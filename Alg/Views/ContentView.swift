import SwiftUI


struct ContentView: View {
    let wordService: WordService
    let learningStateManager: WordLearningStateManager
    let audioPlayerHelper: AudioPlayerHelper
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @AppStorage("hasSelectedDailyGoal") private var hasSelectedDailyGoal = false
    @State private var showTabBar = false
    @State private var selectedTab: Int = 0
    @Environment(\.locale) private var locale
    @ObservedObject private var goalManager = LearningGoalManager.shared

    init(wordService: WordService, learningStateManager: WordLearningStateManager, audioPlayerHelper: AudioPlayerHelper) {
        self.wordService = wordService
        self.learningStateManager = learningStateManager
        self.audioPlayerHelper = audioPlayerHelper
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationView {
                    RandomWordView(showTabBar: $showTabBar, wordService: wordService, learningStateManager: learningStateManager, audioPlayerHelper: audioPlayerHelper)
                }
                .onAppear {
                    audioPlayerHelper.stop()
                }
                .tabItem {
                    Image(systemName: "shuffle")
                }
                .tag(0)

                NavigationView {
                    DictionaryView(wordService: wordService, learningStateManager: learningStateManager, audioPlayerHelper: audioPlayerHelper)
                }
                .onAppear {
                    audioPlayerHelper.stop()
                }
                .tabItem {
                    Image(systemName: "book")
                }
                .tag(1)

                NavigationView {
                    MatchingGameView(wordService: wordService, learningStateManager: learningStateManager)
                }
                .onAppear {
                    audioPlayerHelper.stop()
                }
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                }
                .tag(3)

                NavigationView {
                    SettingsView(wordService: wordService, learningStateManager: learningStateManager, audioPlayerHelper: audioPlayerHelper)
                }
                .onAppear {
                    audioPlayerHelper.stop()
                }
                .tabItem {
                    Image(systemName: "gearshape")
                }
                .tag(2)
            }
            
            DailyProgressBar(goalManager: goalManager, showTabBar: showTabBar, isVisible: showTabBar && selectedTab == 0 && goalManager.dailyGoal > 0 && hasSelectedDailyGoal)
        }
        .animation(.easeInOut(duration: 0.3), value: showTabBar)
        .toolbar(showTabBar ? .visible : .hidden, for: .tabBar)
        .onAppear {
            goalManager.resetIfNewDay()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            goalManager.resetIfNewDay()
        }
    }
}
