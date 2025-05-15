//
//  AudioPlayerHelper.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-16.
//



import Foundation
import AVFoundation
import CryptoKit

struct AudioPlayerHelper {
    static var player: AVAudioPlayer?

    static func playAudio(categoryId: String, entryId: UUID) {
        let fileName = "\(entryId.uuidString.lowercased()).mp3"
        playAudioFile(named: fileName, categoryId: categoryId)
    }

    static func playExample(categoryId: String, entryId: UUID, exampleIndex: Int) {
        let fileName = "\(entryId.uuidString.lowercased())_ex\(exampleIndex).mp3"
        playAudioFile(named: fileName, categoryId: categoryId)
    }

    static func playAudioFile(named fileName: String, categoryId: String) {
        let sanitizedCategoryId = categoryId.lowercased()
        let fullFileName = fileName.replacingOccurrences(of: ".mp3", with: "") + ".mp3"

        let localDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("audio")
            .appendingPathComponent(sanitizedCategoryId)
        let localURL = localDir.appendingPathComponent(fullFileName)

        if FileManager.default.fileExists(atPath: localURL.path) {
            playLocalFile(from: localURL)
            return
        }

        let remoteURL = URL(string: "https://algaudio.blob.core.windows.net/audio/\(sanitizedCategoryId)/\(fullFileName)")!
        try? FileManager.default.createDirectory(at: localDir, withIntermediateDirectories: true)

        URLSession.shared.downloadTask(with: remoteURL) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else { return }
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

    private static func playLocalFile(from url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("❌ Ошибка воспроизведения локального файла: \(error)")
        }
    }
}
