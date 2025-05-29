//
//  WordService.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-29.
//

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
}
