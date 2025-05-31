//
//  WordService.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-29.
//
import Foundation

class WordService {
    private let provider: WordProvider

    init(provider: WordProvider) {
        self.provider = provider
    }

    func allWords() -> [WordEntry] {
        provider.allWords()
    }

    func allCategories() -> [Category] {
        provider.allCategories()
    }

    func wordById(_ id: UUID) -> WordEntry? {
        provider.wordById(id)
    }

    func idsByWord(_ word: String) -> [UUID] {
        provider.idsByWord(word.lowercased()) ?? []
    }
 
    func wordsByString(_ word: String) -> [WordEntry] {
        let normalized = word.lowercased()
        let ids = idsByWord(normalized)
        return ids.compactMap { wordById($0) }
    }
    
    func categoryIdByWordId(_ id: UUID) -> UUID? {
        return provider.categoryIdByWordId(id)
    }
}
