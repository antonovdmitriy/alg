import Foundation

struct WordExample: Decodable {
    let text: String
    let phoneme: String?
}

struct WordForm: Decodable {
    let form: String
    let phoneme: String?
}

struct WordEntry: Identifiable, Decodable {
    let id: UUID
    let word: String
    let version: Int
    let voiceEntries: [UUID]?
    let forms: [WordForm]?
    let translations: [String: String]
    let examples: [WordExample]
    let phoneme: String?
}
