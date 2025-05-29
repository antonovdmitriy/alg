import SwiftUI
import WebKit

struct WordCardView: View {
    @State private var webViewHeight: CGFloat = 100
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    let entry: WordEntry
    let categoryId: String
    let wordService: WordService

    func generateHTML(from text: String) -> String {
        let words = text.components(separatedBy: .whitespaces)
        let rendered = words.map { word -> String in
            let clean = word.trimmingCharacters(in: .punctuationCharacters)
            let ids = wordService.idsByWord(clean)
            if let id = ids.first, let entry = wordService.wordById(id) {
                print("Resolved word: \(entry.word)")
                return "<a href=\"app-word://\(clean)\">\(word)</a>"
            } else {
                return word
            }
        }.joined(separator: " ")

        return """
        <html>
        <head>
        <style>
          body {
            font-family: -apple-system;
            font-size: 28px;
            color: rgba(255,255,255,0.87);
            background: transparent;
          }
          a { color: #007AFF; text-decoration: none; }
        </style>
        </head>
        <body>\(rendered)</body>
        </html>
        """
    }
    
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

                    let combinedExamples = entry.examples.joined(separator: "<br/><br/>")
                    let html = generateHTML(from: combinedExamples)

                    WordExampleWebView(
                        html: html,
                        onWordTapped: { word in
                            print("Tapped word: \(word)")
                        },
                        contentHeight: $webViewHeight
                    )
                    .frame(height: webViewHeight)
                }
                .padding(.bottom, 40)
                .padding()
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
}
