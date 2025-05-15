import SwiftUI

struct ContentView: View {
    let categories = DataLoader.loadCategories()

    var body: some View {
        TabView {
            NavigationView {
                List {
                    ForEach(categories) { category in
                        NavigationLink(destination: WordListView(category: category)) {
                            Text(category.name)
                        }
                    }
                }
                .navigationTitle("category_list_title")
            }
            .tabItem {
                Label("tab_dictionary", systemImage: "book")
            }

            NavigationView {
                RandomWordView(categories: categories)
            }
            .tabItem {
                Label("tab_random", systemImage: "shuffle")
            }
        }
    }
}
