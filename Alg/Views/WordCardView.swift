import SwiftUI
import AVFoundation
import CryptoKit

struct WordCardView: View {
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    let entry: WordEntry
    let categoryId: String
    let wordService: WordService

    @State private var selectedEntry: WordEntry? = nil
    @State private var multipleEntries: [WordEntry] = []
    @State private var showingSelectionSheet = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(entry.word)
                            .font(.largeTitle)
                            .bold()

                        Spacer()

                        Button(action: playWordAudio) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                    }

                    if let forms = entry.forms, !forms.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("word_forms")
                                .font(.headline)

                            ForEach(Array(forms.enumerated()), id: \.offset) { index, form in
                                HStack {
                                    Text(form)
                                    Spacer()
                                    Button(action: {
                                        AudioPlayerHelper.playWordForm(categoryId: categoryId, entryId: entry.id, index: index + 1)
                                    }) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }


                    Text("word_translation \(retrieveTranslation(from: entry.translations, lang: selectedLanguage))")
                        .font(.title3)

                    Text("word_examples")
                        .font(.headline)

                    ForEach(entry.examples.indices, id: \.self) { i in
                        let example = entry.examples[i]

                        TappableText(
                            text: example,
                            tappables: extractTappables(from: example),
                            font: UIFont.systemFont(ofSize: 20)
                        )

                        Button(action: {
                            playExampleAudio(exampleText: example, index: i + 1)
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 40)
                .padding()
                .sheet(item: $selectedEntry) { entry in
                    if let categoryId = wordService.categoryIdByWordId(entry.id) {
                        WordCardView(entry: entry, categoryId: categoryId.uuidString, wordService: wordService)
                    }
                }
                .confirmationDialog("choose_word_title", isPresented: $showingSelectionSheet, titleVisibility: .visible) {
                    ForEach(multipleEntries, id: \.id) { entry in
                        Button("\(entry.word) – \(retrieveTranslation(from: entry.translations, lang: selectedLanguage))") {
                            selectedEntry = entry
                        }
                    }
                }
            }

        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
    }

    func playWordAudio() {
        AudioPlayerHelper.playAudio(categoryId: categoryId, entryId: entry.id)
    }

    func playExampleAudio(exampleText: String, index: Int) {
        AudioPlayerHelper.playExample(categoryId: categoryId, entryId: entry.id, exampleIndex: index)
    }
    
    func sanitize(_ text: String) -> String {
        text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "_")
    }
    
    func extractTappables(from text: String) -> [String: () -> Void] {
        var tappables: [String: () -> Void] = [:]
        let components = text.split(separator: " ").map(String.init)

        for word in components {
            let entries = wordService.wordsByString(word)
            if entries.count == 1 {
                tappables[word] = {
                    selectedEntry = entries[0]
                }
            } else if entries.count > 1 {
                tappables[word] = {
                    multipleEntries = entries
                    showingSelectionSheet = true
                }
            }
        }

        return tappables
    }
}
