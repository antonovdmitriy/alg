//
//  AppDependencies.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-29.
//



import Foundation

class AppDependencies {
    let wordService: WordService

    init() {
        let wordJsonPath = Bundle.main.path(forResource: "word", ofType: "json")!
        let provider = LocalJSONWordProvider(jsonPath: wordJsonPath)
        self.wordService = WordService(provider: provider)
        Task {
            try? await provider.load()
        }
    }
}
