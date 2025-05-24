//
//  SettingsView.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-17.
//


import SwiftUI

struct SettingsView: View {
    let categories: [Category]
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"

    var body: some View {
        let allEntries = categories.flatMap { $0.entries }
        Form {
            Section(header: Text("settings_translation_section")) {
                Picker("settings_language_label", selection: $selectedLanguage) {
                    Text("language_russian").tag("ru")
                    Text("language_english").tag("en")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            Section(header: Text("settings_category_section")) {
                NavigationLink(destination: CategorySelectionView(availableCategories: categories)) {
                    Text("settings_edit_categories")
                }
            }
            Section(header: Text("settings_my_words_section")) {
                NavigationLink(destination: LearnedWordsView(entries: allEntries)) {
                    Label("settings_learned_words", systemImage: "checkmark")
                }
                NavigationLink(destination: FavoriteWordsView(entries: allEntries)) {
                    Label("settings_favorite_words", systemImage: "star")
                }
                NavigationLink(destination: IgnoredWordsView(entries: allEntries)) {
                    Label("settings_ignored_words", systemImage: "nosign")
                }
            }
        }
        .navigationTitle("settings_title")
    }
}

struct LearnedWordsView: View {
    let entries: [WordEntry]
    var body: some View {
        FilteredWordListView(
            title: "Выученные слова",
            allEntries: entries,
            type: .known,
            categoryIdProvider: { _ in "learned" }
        )
    }
}

struct FavoriteWordsView: View {
    let entries: [WordEntry]
    var body: some View {
        FilteredWordListView(
            title: "Избранные слова",
            allEntries: entries,
            type: .favorite,
            categoryIdProvider: { _ in "favorite" }
        )
    }
}

struct IgnoredWordsView: View {
    let entries: [WordEntry]
    var body: some View {
        FilteredWordListView(
            title: "Скрытые слова",
            allEntries: entries,
            type: .ignored,
            categoryIdProvider: { _ in "ignored" }
        )
    }
}
