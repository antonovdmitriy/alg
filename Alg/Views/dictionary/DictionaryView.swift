import SwiftUI

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
