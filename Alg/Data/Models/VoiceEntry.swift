import Foundation

struct VoiceEntry: Decodable {
    let id: UUID
    let voiceName: String
    let provider: String
    let sampleUrl: URL
}
