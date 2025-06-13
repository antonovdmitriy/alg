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

struct DictionaryView: View {
    let wordService: WordService
    let learningStateManager: WordLearningStateManager
    let audioPlayerHelper: AudioPlayerHelper
    @Environment(\.locale) private var locale
    @State private var searchText = ""
    @AppStorage("selectedSearchLanguage") private var selectedSearchLang = "sv"
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @State private var hasInitializedSearchLang = false
    @State private var isSearchFocused: Bool = false

    var filteredResults: [WordEntry] {
        if searchText.isEmpty {
            return []
        }

        if selectedSearchLang == "sv" {
            return wordService.entriesStartingWith(prefix: searchText)
        } else {
            return wordService.entriesMatchingTranslation(prefix: searchText, lang: selectedSearchLang)
        }
    }

    var body: some View {
        VStack {
            Picker("Search mode", selection: $selectedSearchLang) {
                Text("search_by_word").tag("sv")
                Text("search_by_translation").tag(selectedLanguage)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                if searchText.isEmpty {
                    ForEach(wordService.allCategories()) { category in
                        NavigationLink(
                            destination: WordListView(
                                category: category,
                                wordService: wordService,
                                learningStateManager: learningStateManager,
                                audioPlayerHelper: audioPlayerHelper
                            )
                        ) {
                     Text(category.translations[selectedLanguage] ?? category.translations["en"] ?? "")
                        }
                    }
                } else {
                    ForEach(filteredResults) { entry in
                        NavigationLink(destination: WordCardView(entry: entry, categoryId: wordService.categoryIdByWordId(entry.id)?.uuidString ?? "", wordService: wordService, learningStateManager: learningStateManager, audioPlayerHelper: audioPlayerHelper)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.word)
                                    .font(.headline)
                                if let translation = entry.translations[selectedLanguage] {
                                    Text(translation)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .onAppear {
            if !hasInitializedSearchLang {
                let validValues = ["sv", selectedLanguage]
                if !validValues.contains(selectedSearchLang) {
                    selectedSearchLang = selectedLanguage
                }
                hasInitializedSearchLang = true
            }
        }
        .onChange(of: selectedLanguage) { oldLang, newLang in
            let validValues = ["sv", newLang]
            if !validValues.contains(selectedSearchLang) {
                selectedSearchLang = newLang
            }
        }
        .navigationTitle("dictionary_title")
        .searchable(text: $searchText, prompt: Text("search_prompt")){
            
        }
    }
}
