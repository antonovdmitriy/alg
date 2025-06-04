

import Foundation

protocol VoiceProvider {
    func allVoices() -> [VoiceEntry]
    func voiceById(_ id: UUID) -> VoiceEntry?
}

class LocalJSONVoiceProvider: VoiceProvider {
    private let jsonPath: String
    private var voices: [VoiceEntry] = []
    private var index: [UUID: VoiceEntry] = [:]

    init(jsonPath: String) {
        self.jsonPath = jsonPath
    }

    func load() async throws {
        let url = URL(fileURLWithPath: jsonPath)
        let data = try Data(contentsOf: url)
        self.voices = try JSONDecoder().decode([VoiceEntry].self, from: data)
        self.index = Dictionary(uniqueKeysWithValues: voices.map { ($0.id, $0) })
    }

    func allVoices() -> [VoiceEntry] {
        voices
    }

    func voiceById(_ id: UUID) -> VoiceEntry? {
        index[id]
    }
}
