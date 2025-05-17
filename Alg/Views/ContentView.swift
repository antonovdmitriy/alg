import SwiftUI

struct ContentView: View {
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    let categories = DataLoader.loadCategories()

    var body: some View {
        TabView {
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
            .tabItem {
                Image(systemName: "book")
            }

            NavigationView {
                RandomWordView(categories: categories)
            }
            .tabItem {
                Image(systemName: "shuffle")
            }

            NavigationView {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape")
            }
        }
    }
}
