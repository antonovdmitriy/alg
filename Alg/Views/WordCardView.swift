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
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(entry.word)
                            .font(.system(size: 40, weight: .bold, design: .default))

                        Spacer()

                        Button(action: playWordAudio) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.secondary)
                                .imageScale(.large)
                                .padding(10)
                                .background(Circle().fill(Color.blue.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Forms:")
                            .font(.headline)

                        let forms = entry.forms ?? []
                        let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

                        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                            ForEach(Array(forms.enumerated()), id: \.offset) { index, form in
                                Button(action: {
                                    AudioPlayerHelper.playWordForm(categoryId: categoryId, entryId: entry.id, index: index + 1)
                                }) {
                                    HStack(spacing: 6) {
                                        Text(form)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .minimumScaleFactor(0.8)
                                        Image(systemName: "speaker.wave.2.fill")
                                            .imageScale(.small)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.1)))
                                    .foregroundColor(.primary)
                                    .font(.system(size: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Translation:")
                            .font(.headline)
                        Text(retrieveTranslation(from: entry.translations, lang: selectedLanguage))
                            .italic()
                            .font(.title3)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Examples:")
                            .font(.headline)

                        ForEach(entry.examples.indices, id: \.self) { i in
                            let example = entry.examples[i]

                            HStack(alignment: .top, spacing: 8) {
                                Button(action: {
                                    playExampleAudio(exampleText: example, index: i + 1)
                                }) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 2)

                                TappableText(
                                    text: example,
                                    tappables: extractTappables(from: example),
                                    font: UIFont.systemFont(ofSize: 18)
                                )
                            }
                        }
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
