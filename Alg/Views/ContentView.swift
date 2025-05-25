import SwiftUI

struct ContentView: View {
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    let categories: [Category]
    @State private var showTabBar = false
    @Environment(\.locale) private var locale

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
