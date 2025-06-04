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
    func entriesStartingWith(prefix: String) -> [WordEntry]
    func entriesMatchingTranslation(prefix: String, lang: String) -> [WordEntry]
}

class LocalJSONWordProvider: WordProvider {
    class TrieNode {
        var children: [Character: TrieNode] = [:]
        var ids: [UUID] = []
    }

    private let jsonPath: String
    private var entries: [WordEntry] = []
    private var categories: [Category] = []
    private var wordByIdIndex: [UUID: WordEntry] = [:]
    private var formToIdIndex: [String: [UUID]] = [:]
    private var categoryIdByWordId: [UUID: UUID] = [:]
    private var root = TrieNode()
    private var translationRoots: [String: TrieNode] = [:]

    init(jsonPath: String) {
        self.jsonPath = jsonPath
    }

    func load() async throws {
        self.categories = loadCategories()
        self.entries = self.categories.flatMap { $0.entries }
        self.entries.forEach { entry in
            insertIntoTrie(entry.word, id: entry.id)
            for form in entry.forms ?? [] {
                insertIntoTrie(form.form, id: entry.id)
            }
            for (lang, translation) in entry.translations {
                insertIntoTranslationTrie(translation, lang: lang, id: entry.id)
            }
        }
        self.wordByIdIndex = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        self.formToIdIndex = entries.reduce(into: [:]) { result, entry in
            result[entry.word, default: []].append(entry.id)
            for form in entry.forms ?? [] {
                result[form.form, default: []].append(entry.id)
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
        do {
            let data = try Data(contentsOf: url)
            let categories = try JSONDecoder().decode([Category].self, from: data)
            return categories
        } catch {
            print("Failed to load categories from \(url): \(error)")
            return []
        }
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
    
    private func insertIntoTrie(_ word: String, id: UUID) {
        let lower = word.lowercased()
        var current = root
        for char in lower {
            let next = current.children[char] ?? TrieNode()
            current.children[char] = next
            current = next
        }
        current.ids.append(id)

        if lower.hasPrefix("en "), lower.count > 3 {
            let trimmed = String(lower.dropFirst(3))
            insertIntoTrie(trimmed, id: id)
        } else if lower.hasPrefix("ett "), lower.count > 4 {
            let trimmed = String(lower.dropFirst(4))
            insertIntoTrie(trimmed, id: id)
        }
    }

    func entriesStartingWith(prefix: String) -> [WordEntry] {
        var node = root
        for char in prefix.lowercased() {
            guard let next = node.children[char] else { return [] }
            node = next
        }

        var results: [UUID] = []
        collectIds(from: node, into: &results)
        let uniqueIds = Set(results)
        return uniqueIds.compactMap { wordById($0) }
    }

    private func collectIds(from node: TrieNode, into array: inout [UUID]) {
        array.append(contentsOf: node.ids)
        for child in node.children.values {
            collectIds(from: child, into: &array)
        }
    }

    private func insertIntoTranslationTrie(_ word: String, lang: String, id: UUID) {
        let node = translationRoots[lang] ?? TrieNode()
        var current = node
        for char in word.lowercased() {
            let next = current.children[char] ?? TrieNode()
            current.children[char] = next
            current = next
        }
        current.ids.append(id)
        translationRoots[lang] = node
    }

    func entriesMatchingTranslation(prefix: String, lang: String) -> [WordEntry] {
        print("Searching translations for lang: '\(lang)', prefix: '\(prefix)'")
        guard let nodeRoot = translationRoots[lang] else { return [] }
        var node = nodeRoot
        for char in prefix.lowercased() {
            guard let next = node.children[char] else { return [] }
            node = next
        }
        var results: [UUID] = []
        collectIds(from: node, into: &results)
        return results.compactMap { wordById($0) }
    }
}
