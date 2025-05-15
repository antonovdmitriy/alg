import SwiftUI
import AVFoundation
import CryptoKit

struct WordCardView: View {
    let entry: WordEntry
    let categoryId: String
    var onClose: () -> Void

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(entry.word.components(separatedBy: ",").first ?? entry.word)
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

                    if entry.word.contains(",") {
                        Text("word_forms \(entry.word)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Text("word_translation \(entry.translation)")
                        .font(.title3)

                    Text("word_examples")
                        .font(.headline)

                    ForEach(entry.examples.indices, id: \.self) { i in
                        let example = entry.examples[i]
                        HStack(alignment: .top) {
                            Text("• \(example)")
                                .multilineTextAlignment(.leading)

                            Spacer()

                            Button(action: {
                                playExampleAudio(exampleText: example, index: i + 1)
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
