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
    
    func wordsByStringConsideringArticles(_ word: String) -> [WordEntry] {
        let normalized = word.lowercased()
        let ids = idsByWordConsideringArticles(normalized)
        return ids.compactMap { wordById($0) }
    }
    
    func categoryIdByWordId(_ id: UUID) -> UUID? {
        return provider.categoryIdByWordId(id)
    }
    
    func idsByWordConsideringArticles(_ word: String) -> [UUID] {
        let base = word.lowercased()
        let direct = provider.idsByWord(base) ?? []
        
        if !direct.isEmpty {
            return direct
        }
        
        guard !base.contains(" ") else { return [] }
        
        let withEn = provider.idsByWord("en \(base)") ?? []
        let withEtt = provider.idsByWord("ett \(base)") ?? []
        
        return withEn + withEtt
    }
    
    func entriesStartingWith(prefix: String) -> [WordEntry] {
        return provider.entriesStartingWith(prefix: prefix)
    }

    func entriesMatchingTranslation(prefix: String, lang: String) -> [WordEntry] {
        return provider.entriesMatchingTranslation(prefix: prefix, lang: lang)
    }
}

