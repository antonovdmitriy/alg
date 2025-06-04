import Foundation

class VoiceService {
    private let provider: VoiceProvider

    init(provider: VoiceProvider) {
        self.provider = provider
    }

    func allVoices() -> [VoiceEntry] {
        provider.allVoices()
    }

    func voiceById(_ id: UUID) -> VoiceEntry? {
        provider.voiceById(id)
    }
}
