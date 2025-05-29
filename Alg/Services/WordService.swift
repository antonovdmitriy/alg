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
        provider.idsByWord(word) ?? []
    }
}
