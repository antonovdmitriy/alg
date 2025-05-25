import SwiftUI

struct ContentView: View {
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    let categories: [Category]
    @State private var showTabBar = false

    init(categories: [Category]) {
        self.categories = categories

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            NavigationView {
                RandomWordView(categories: categories, showTabBar: $showTabBar)
            }
            .onAppear {
                AudioPlayerHelper.stop()
            }
            .tabItem {
                Image(systemName: "shuffle")
            }

            NavigationView {
                List {
                    ForEach(categories) { category in
                        NavigationLink(destination: WordListView(category: category)) {
                            Text(retrieveTranslation(from: category.translations, lang: selectedLanguage))
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
                SettingsView(categories: categories)
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
