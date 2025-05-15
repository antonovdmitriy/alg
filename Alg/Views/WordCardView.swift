import SwiftUI
import AVFoundation
import CryptoKit

struct WordCardView: View {
    let entry: WordEntry
    let categoryId: String
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
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
        .padding()
    }

    func playWordAudio() {
        let fileName = "\(entry.id).mp3".lowercased()
        playAudioFile(named: fileName)
    }

    func playExampleAudio(exampleText: String, index: Int) {
        let fileName = "\(entry.id)_ex\(index).mp3".lowercased()
        playAudioFile(named: fileName)
    }

    func playAudioFile(named fileName: String) {
        let sanitizedCategoryId = categoryId.lowercased()
        let baseFileName = fileName.replacingOccurrences(of: ".mp3", with: "")
        let fullFileName = baseFileName + ".mp3"

        // Локальный путь к файлу
        let localDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("audio")
            .appendingPathComponent(sanitizedCategoryId)
        let localURL = localDir.appendingPathComponent(fullFileName)

        // 🔄 Если файл уже скачан — играем из кэша
        if FileManager.default.fileExists(atPath: localURL.path) {
            playLocalFile(from: localURL)
            return
        }

        // 🌐 Формируем URL к Azure
        let remoteURL = URL(string: "https://algaudio.blob.core.windows.net/audio/\(sanitizedCategoryId)/\(fullFileName)")!

        // Создаём папку если нужно
        try? FileManager.default.createDirectory(at: localDir, withIntermediateDirectories: true)

        // 📥 Скачиваем и сохраняем
        URLSession.shared.downloadTask(with: remoteURL) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                print("❌ Ошибка загрузки аудио: \(error?.localizedDescription ?? "неизвестная ошибка")")
                return
            }

            do {
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                DispatchQueue.main.async {
                    playLocalFile(from: localURL)
                }
            } catch {
                print("❌ Ошибка сохранения файла: \(error)")
            }
        }.resume()
    }

    func playLocalFile(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("❌ Ошибка воспроизведения локального файла: \(error)")
        }
    }
    
    func sanitize(_ text: String) -> String {
        text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "_")
    }
}
