import Foundation

enum CEFRLevel: String, Codable {
    case a1, a2, b1, b2, c1, c2
}

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
    let level: CEFRLevel?
    let examples: [WordExample]
    let phoneme: String?
}
