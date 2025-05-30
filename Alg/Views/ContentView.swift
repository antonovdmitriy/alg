import SwiftUI

struct ContentView: View {
    let wordService: WordService
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @State private var showTabBar = false
    @State private var selectedTab: Int = 0
    @Environment(\.locale) private var locale
    @ObservedObject private var goalManager = LearningGoalManager.shared

    init(wordService: WordService) {
        self.wordService = wordService

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
                    RandomWordView(showTabBar: $showTabBar, wordService: wordService)
                }
                .onAppear {
                    AudioPlayerHelper.stop()
                }
                .tabItem {
                    Image(systemName: "shuffle")
                }
                .tag(0)

                NavigationView {
                    List {
                        ForEach(wordService.allCategories()) { category in
                            NavigationLink(destination: WordListView(category: category, wordService: wordService)) {
                                Text(category.translations[locale.language.languageCode?.identifier ?? ""] ?? category.translations["en"] ?? "")
                            }
                        }
                    }
                    .navigationTitle("category_list_title")
                }
                .onAppear {
                    AudioPlayerHelper.stop()
                }
                .tabItem {
                    Image(systemName: "book")
                }
                .tag(1)

                NavigationView {
                    SettingsView(wordService: wordService)
                }
                .onAppear {
                    AudioPlayerHelper.stop()
                }
                .tabItem {
                    Image(systemName: "gearshape")
                }
                .tag(2)
            }
            
            DailyProgressBar(goalManager: goalManager, showTabBar: showTabBar, isVisible: showTabBar && selectedTab == 0 && goalManager.dailyGoal > 0)
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
