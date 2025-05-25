//
//  FilteredWordListView.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-25.
//


import SwiftUI
import Foundation

enum WordListType {
    case favorite
    case known
    case ignored
}

struct FilteredWordListView: View {
    let title: String
    let entries: [(WordEntry, UUID)]
    let onDelete: (UUID) -> Void
    let onClear: () -> Void
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @State private var showConfirmation = false

    var body: some View {
        VStack {
            if entries.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 48))
                        .foregroundColor(.green.opacity(0.7))
                    Text(NSLocalizedString("empty_word_list", comment: ""))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(entries, id: \.0.id) { (entry, categoryId) in
                        NavigationLink(destination: WordDetailView(entry: entry, categoryId: categoryId.uuidString)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.word)
                                    .font(.headline)
                                if let translation = entry.translations[selectedLanguage] {
                                    Text(translation)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            onDelete(entries[index].0.id)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text(NSLocalizedString("clear_alert_title", comment: "")),
                message: Text(NSLocalizedString("clear_alert_message", comment: "")),
                primaryButton: .destructive(Text(NSLocalizedString("clear_alert_confirm", comment: ""))) {
                    onClear()
                },
                secondaryButton: .cancel(Text(NSLocalizedString("clear_alert_cancel", comment: "")))
            )
        }
        .navigationTitle(title)
        .toolbar {
            if !entries.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("clear_button_title", comment: "")) {
                        showConfirmation = true
                    }
                }
            }
        }
    }
}
