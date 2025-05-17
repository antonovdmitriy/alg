//
//  LanguageSelectionView.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-17.
//


import SwiftUI

struct LanguageSelectionView: View {
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @AppStorage("hasSelectedTranslationLanguage") private var hasSelectedLanguage = false

    var body: some View {
        VStack(spacing: 32) {
            Text("select_translation_language")
                .font(.title2)
                .multilineTextAlignment(.center)

            HStack(spacing: 24) {
                Button(action: {
                    selectedLanguage = "ru"
                    hasSelectedLanguage = true
                }) {
                    HStack {
                        Text("🇷🇺")
                        Text("language_russian")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
                }

                Button(action: {
                    selectedLanguage = "en"
                    hasSelectedLanguage = true
                }) {
                    HStack {
                        Text("🇬🇧")
                        Text("language_english")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}
