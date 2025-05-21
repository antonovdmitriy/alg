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
        }
        .navigationTitle("settings_title")
    }
}
