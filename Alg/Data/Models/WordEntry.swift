import Foundation

struct WordEntry: Identifiable, Decodable {
    let id: UUID
    let word: String
    let forms: [String]?
    let translations: [String: String]
    let examples: [String]
}
