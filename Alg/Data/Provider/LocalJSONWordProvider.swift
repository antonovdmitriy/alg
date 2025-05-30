//
//  JSONWordProvider.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-29.
//

import Foundation

protocol WordProvider {
    func load() async throws
    func allWords() -> [WordEntry]
    func allCategories() -> [Category]
    func wordById(_ id: UUID) -> WordEntry?
    func idsByWord(_ form: String) -> [UUID]?
    func categoryIdByWordId(_ id: UUID) -> UUID?
}

class LocalJSONWordProvider: WordProvider {
    private let jsonPath: String
    private var entries: [WordEntry] = []
    private var categories: [Category] = []
    private var wordByIdIndex: [UUID: WordEntry] = [:]
    private var formToIdIndex: [String: [UUID]] = [:]
    private var categoryIdByWordId: [UUID: UUID] = [:]

    init(jsonPath: String) {
        self.jsonPath = jsonPath
    }

    func load() async throws {
        self.categories = loadCategories()
        self.entries = self.categories.flatMap { $0.entries }
        self.wordByIdIndex = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        self.formToIdIndex = entries.reduce(into: [:]) { result, entry in
            result[entry.word, default: []].append(entry.id)
            for form in entry.forms ?? [] {
                result[form, default: []].append(entry.id)
            }
        }
        self.categoryIdByWordId = categories.reduce(into: [:]) { result, category in
            for entry in category.entries {
                result[entry.id] = category.id
            }
        }
    }

    func allWords() -> [WordEntry] {
        entries
    }

    func allCategories() -> [Category] {
        categories
    }
    
    private func loadCategories() -> [Category] {
        let url = URL(fileURLWithPath: jsonPath)
        guard let data = try? Data(contentsOf: url),
              let categories = try? JSONDecoder().decode([Category].self, from: data) else {
            return []
        }
        return categories
    }
    
    func idsByWord(_ form: String) -> [UUID]? {
        formToIdIndex[form]
    }
    
    func wordById(_ id: UUID) -> WordEntry? {
        wordByIdIndex[id]
    }
    
    func categoryIdByWordId(_ id: UUID) -> UUID? {
        categoryIdByWordId[id]
    }
    
}
