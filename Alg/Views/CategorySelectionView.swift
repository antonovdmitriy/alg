//
//  CategorySelectionView.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-21.
//


import SwiftUI

struct CategorySelectionView: View {
    let availableCategories: [Category]

    let allCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    @AppStorage("selectedCategories") private var selectedCategoriesData: Data = Data()
    @AppStorage("hasSelectedCategories") private var hasSelectedCategories = false
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"

    @State private var selected: Set<UUID> = []

    var body: some View {
        VStack(spacing: 24) {
            Text("select_categories")
                .font(.title2)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(radius: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selected.contains(allCategoryId) ? Color.accentColor : Color.clear, lineWidth: 2)
                            )

                        Toggle(isOn: Binding(
                            get: { selected.contains(allCategoryId) },
                            set: { isOn in
                                if isOn {
                                    selected.insert(allCategoryId)
                                } else {
                                    selected.remove(allCategoryId)
                                }
                            }
                        )) {
                            Text("category_all")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)

                    ForEach(availableCategories, id: \.id) { category in
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .shadow(radius: 1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selected.contains(category.id) ? Color.accentColor : Color.clear, lineWidth: 2)
                                )

                            Toggle(isOn: Binding(
                                get: { selected.contains(category.id) },
                                set: { isOn in
                                    if isOn {
                                        selected.insert(category.id)
                                    } else {
                                        selected.remove(category.id)
                                    }
                                }
                            )) {
                                Text(retrieveTranslation(from: category.translations, lang: selectedLanguage).capitalized)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemBackground))

            Button(action: {
                saveSelectedCategories()
                hasSelectedCategories = true
            }) {
                Text("continue")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            loadSelectedCategories()
        }
    }

    func saveSelectedCategories() {
        if let data = try? JSONEncoder().encode(Array(selected)) {
            selectedCategoriesData = data
        }
    }

    func loadSelectedCategories() {
        if let categories = try? JSONDecoder().decode([UUID].self, from: selectedCategoriesData) {
            selected = Set(categories)
        }
    }
}
