//
//  AudioPlayerHelper.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-16.
//




import Foundation
import AVFoundation
import CryptoKit

private let baseRemoteURL = "https://algaudio.blob.core.windows.net"

final class AudioPlayerHelper {
    private let wordService: WordService
    private let voiceService: VoiceService
    private var player: AVAudioPlayer?
    private let audioRootDir = "audio"

    init(wordService: WordService, voiceService: VoiceService) {
        self.wordService = wordService
        self.voiceService = voiceService
    }

    func playAudio(entryId: UUID) {
        let fileName = "\(entryId.uuidString.lowercased()).mp3"
        guard let entry = wordService.wordById(entryId) else { return }
        playAudioFile(entry: entry, fileName: fileName)
    }

    func playExample(entryId: UUID, exampleIndex: Int) {
        let fileName = "\(entryId.uuidString.lowercased())_ex\(exampleIndex).mp3"
        guard let entry = wordService.wordById(entryId) else { return }
        playAudioFile(entry: entry, fileName: fileName)
    }
    
    func playWordForm(entryId: UUID, index: Int) {
        let fileName = "\(entryId.uuidString.lowercased())_form\(index).mp3"
        guard let entry = wordService.wordById(entryId) else { return }
        playAudioFile(entry: entry, fileName: fileName)
    }
    
    private func playAudioFile(entry: WordEntry, fileName: String) {
        downloadIfNeeded(entry: entry, fileName: fileName) { localURL in
            guard let localURL = localURL else { return }
            DispatchQueue.main.async {
                self.playLocalFile(from: localURL)
            }
        }
    }

    private func downloadIfNeeded(entry: WordEntry, fileName: String, completion: ((URL?) -> Void)? = nil) {
        guard let categoryId = wordService.categoryIdByWordId(entry.id) else {
            completion?(nil)
            return
        }
        let sanitizedCategoryId = categoryId.uuidString.lowercased()
        
        let localDir: URL = {
            if entry.version == -1 || voiceId(for: entry) == nil {
                return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                    .appendingPathComponent(audioRootDir)
                    .appendingPathComponent(sanitizedCategoryId)
            } else {
                let voiceId = voiceId(for: entry)!
                return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                    .appendingPathComponent(audioRootDir)
                    .appendingPathComponent(sanitizedCategoryId)
                    .appendingPathComponent(entry.id.uuidString.lowercased())
                    .appendingPathComponent("\(entry.version)")
                    .appendingPathComponent(voiceId.uuidString.lowercased())
            }
        }()
        let localURL = localDir.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: localURL.path) {
            completion?(localURL)
            return
        }

        let fullRemotePath = "\(baseRemoteURL)/\(audioRootDir)/\(sanitizedCategoryId)"

        let remoteURL: URL
        if entry.version > 0, let voiceId = voiceId(for: entry) {
            remoteURL = URL(string: "\(fullRemotePath)/\(entry.id.uuidString.lowercased())/\(entry.version)/\(voiceId.uuidString.lowercased())/\(fileName)")!
        } else {
            remoteURL = URL(string: "\(fullRemotePath)/\(fileName)")!
        }
        
        try? FileManager.default.createDirectory(at: localDir, withIntermediateDirectories: true)

        URLSession.shared.downloadTask(with: remoteURL) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else {
                completion?(nil)
                return
            }
            do {
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                completion?(localURL)
            } catch {
                print("❌ Ошибка сохранения файла: \(error)")
                completion?(nil)
            }
        }.resume()
    }

    private func playLocalFile(from url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            stop()
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("❌ Ошибка воспроизведения локального файла: \(error)")
        }
    }

    func stop() {
        if player?.isPlaying == true {
            player?.stop()
            player = nil
        }
    }

    func prefetchAudio(entryId: UUID) {
        let fileName = "\(entryId.uuidString.lowercased()).mp3"
        guard let entry = wordService.wordById(entryId) else { return }
        downloadIfNeeded(entry: entry, fileName: fileName)
    }

    private func voiceId(for entry: WordEntry) -> UUID? {
        // TODO: make more smart when we will get more than one voice.
        guard let voices = entry.voiceEntries, let first = voices.first else { return nil }
        return first
    }
}
