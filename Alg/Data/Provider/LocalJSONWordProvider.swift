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
}

class LocalJSONWordProvider: WordProvider {
    private let jsonPath: String
    private var entries: [WordEntry] = []
    private var categories: [Category] = []

    init(jsonPath: String) {
        self.jsonPath = jsonPath
    }

    func load() async throws {
        self.categories = loadCategories()
        self.entries = self.categories.flatMap { $0.entries }
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
}
