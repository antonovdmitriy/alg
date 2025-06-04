//
//  AppDependencies.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-29.
//



import Foundation

class AppDependencies {
    let wordService: WordService
    let voiceService: VoiceService
    let audioPlayerHelper: AudioPlayerHelper
    let learningStateManager: WordLearningStateManager
    init() {
        let wordJsonPath = Bundle.main.path(forResource: "word", ofType: "json")!
        let provider = LocalJSONWordProvider(jsonPath: wordJsonPath)
        self.wordService = WordService(provider: provider)
        
        let voiceJsonPath = Bundle.main.path(forResource: "voice", ofType: "json")!
        let voiceProvider = LocalJSONVoiceProvider(jsonPath: voiceJsonPath)
        self.voiceService = VoiceService(provider: voiceProvider)
        
        self.audioPlayerHelper = AudioPlayerHelper(wordService: wordService, voiceService: voiceService)
        
        Task {
            try? await provider.load()
        }
        Task {
            try? await voiceProvider.load()
        }
        
        learningStateManager = WordLearningStateManager()
    }
}
