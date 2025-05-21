//
//  CategorySelectionView.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-21.
//


import SwiftUI

struct CategorySelectionView: View {
    let availableCategories: [Category]

    
    let tileColors: [Color] = [
        .red.opacity(0.2),
        .green.opacity(0.2),
        .blue.opacity(0.2),
        .orange.opacity(0.2),
        .purple.opacity(0.2),
        .pink.opacity(0.2),
        .teal.opacity(0.2),
        .indigo.opacity(0.2)
    ]

    @AppStorage("selectedCategories") private var selectedCategoriesData: Data = Data()
    @AppStorage("hasSelectedCategories") private var hasSelectedCategories = false
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"

    @State private var selected: Set<UUID> = []

    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            Text("select_categories")
                .font(.title2)
                .multilineTextAlignment(.center)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    Button(action: {
                        if selected.contains(Category.allCategoryId) {
                            selected.remove(Category.allCategoryId)
                        } else {
                            selected.insert(Category.allCategoryId)
                        }
                    }) {
                        Text("category_all")
                            .font(.system(size: 16, weight: .medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                            .frame(width: 150, height: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: colorScheme == .dark ? [.gray.opacity(0.4), .black.opacity(0.3)] : [.gray.opacity(0.2), .white.opacity(0.2)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(Color.primary.opacity(selected.contains(Category.allCategoryId) ? 0.3 : 0), lineWidth: selected.contains(Category.allCategoryId) ? 2 : 0)
                                    )
                                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())

                    ForEach(Array(availableCategories.enumerated()), id: \.element.id) { index, category in
                        Button(action: {
                            if selected.contains(category.id) {
                                selected.remove(category.id)
                            } else {
                                selected.insert(category.id)
                            }
                        }) {
                            Text(retrieveTranslation(from: category.translations, lang: selectedLanguage).capitalized)
                                .font(.system(size: 16, weight: .medium))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .frame(width: 150, height: 100)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    tileColors[index % tileColors.count],
                                                    tileColors[index % tileColors.count].opacity(0.4)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .strokeBorder(Color.primary.opacity(selected.contains(category.id) ? 0.3 : 0), lineWidth: selected.contains(category.id) ? 2 : 0)
                                        )
                                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 8)
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
