//
//  CategorySelectionView.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-21.
//


import SwiftUI

struct CategorySelectionView: View {
    
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

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

    @State private var selected: Set<UUID> = []

    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    @Environment(\.colorScheme) var colorScheme

    let availableCategories: [Category]

    init(wordService: WordService) {
        self.availableCategories = wordService.allCategories()
    }

    var body: some View {
        VStack(spacing: 24) {
            EmptyView()

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
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
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
                            Text((category.translations[selectedLanguage] ?? category.translations["en"] ?? "").capitalized)
                                .font(.system(size: 16, weight: .medium))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .background(
                                    backgroundForTile(color: tileColors[index % tileColors.count], isSelected: selected.contains(category.id))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 16)
                // Removed .padding(.horizontal, 8) to let grid stretch to safe area edges
            }
            .scrollContentBackground(.hidden)
            // Background now applied to root VStack instead of just ScrollView

            Button(action: {
                saveSelectedCategories()
                hasSelectedCategories = true
                dismiss()
            }) {
                Text("continue")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .padding()
        .onAppear {
            loadSelectedCategories()
        }
        .navigationTitle(Text(NSLocalizedString("select_categories", comment: "")))
        .navigationBarTitleDisplayMode(.inline)
    }

    func backgroundForTile(color: Color, isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.primary.opacity(isSelected ? 0.3 : 0), lineWidth: isSelected ? 2 : 0)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
    }

    func saveSelectedCategories() {
        var toSave = selected
        if toSave.isEmpty {
            toSave.insert(Category.allCategoryId)
        }
        if let data = try? JSONEncoder().encode(Array(toSave)) {
            selectedCategoriesData = data
        }
    }

    func loadSelectedCategories() {
        if let categories = try? JSONDecoder().decode([UUID].self, from: selectedCategoriesData) {
            selected = Set(categories)
        }
    }
}
