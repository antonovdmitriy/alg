import SwiftUI

struct ContentView: View {
    let wordService: WordService
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @State private var showTabBar = false
    @Environment(\.locale) private var locale

    init(wordService: WordService) {
        self.wordService = wordService

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            NavigationView {
                RandomWordView(showTabBar: $showTabBar, wordService: wordService)
            }
            .onAppear {
                AudioPlayerHelper.stop()
            }
            .tabItem {
                Image(systemName: "shuffle")
            }

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

            NavigationView {
                SettingsView(wordService: wordService)
            }
            .onAppear {
                AudioPlayerHelper.stop()
            }
            .tabItem {
                Image(systemName: "gearshape")
            }
        }
        .toolbar(showTabBar ? .visible : .hidden, for: .tabBar)
    }
}
