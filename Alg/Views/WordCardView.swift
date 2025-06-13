import SwiftUI
import AVFoundation
import CryptoKit

struct WordCardView: View {
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @AppStorage("hideLinksToKnownWords") private var hideLinksToKnownWords = false
    let entry: WordEntry
    let categoryId: String
    let wordService: WordService
    let learningStateManager: WordLearningStateManager
    let audioPlayerHelper: AudioPlayerHelper

    @State private var selectedEntry: WordEntry? = nil
    @State private var multipleEntries: [WordEntry] = []
    @State private var showingSelectionSheet = false
    @State private var feedbackMessage: String?
    @State private var feedbackMessageId = UUID()
    
var body: some View {
        return ZStack(alignment: .top) {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(pinnedViews: [.sectionHeaders]) {
                        Section(
                            header:
                                VStack(alignment: .leading, spacing: 20) {
                                    HStack {
                                        Text(entry.word)
                                            .font(.system(size: 40, weight: .bold, design: .default))
                                        Spacer()
                                        Button(action: playWordAudio) {
                                            Image(systemName: "speaker.wave.2.fill")
                                                .foregroundColor(.secondary)
                                                .imageScale(.large)
                                                .padding(10)
                                                .background(Circle().fill(Color.blue.opacity(0.1)))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    HStack(spacing: 16) {
                                        // Known button
                                        Button(action: {
                                            feedbackMessageId = UUID()
                                            if !learningStateManager.isKnown(entry.id) {
                                                learningStateManager.toggleKnown(entry.id)
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    feedbackMessage = NSLocalizedString("marked_as_known", comment: "")
                                                }
                                            } else {
                                                learningStateManager.toggleKnown(entry.id)
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    feedbackMessage = NSLocalizedString("unmarked_as_known", comment: "")
                                                }
                                            }
                                            withAnimation(.spring()) {}
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                feedbackMessage = nil
                                            }
                                        }) {
                                            Image(systemName: learningStateManager.isKnown(entry.id) ? "checkmark.circle.fill" : "checkmark.circle")
                                                .font(.system(size: 16, weight: .medium))
                                                .frame(width: 36, height: 36)
                                                .foregroundColor(learningStateManager.isKnown(entry.id) ? .green : .primary)
                                                .background(
                                                    Circle()
                                                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                                                        .background(Circle().fill(Color.primary.opacity(0.05)))
                                                )
                                        }
                                        // Ignored button
                                        Button(action: {
                                            feedbackMessageId = UUID()
                                            if !learningStateManager.isIgnored(entry.id) {
                                                learningStateManager.toggleIgnored(entry.id)
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    feedbackMessage = NSLocalizedString("marked_as_ignored", comment: "")
                                                }
                                            } else {
                                                learningStateManager.toggleIgnored(entry.id)
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    feedbackMessage = NSLocalizedString("unmarked_as_ignored", comment: "")
                                                }
                                            }
                                            withAnimation(.spring()) {}
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                feedbackMessage = nil
                                            }
                                        }) {
                                            Image(systemName: learningStateManager.isIgnored(entry.id) ? "eye.slash" : "eye")
                                                .font(.system(size: 16, weight: .medium))
                                                .frame(width: 36, height: 36)
                                                .foregroundColor(.primary)
                                                .background(
                                                    Circle()
                                                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                                                        .background(Circle().fill(Color.primary.opacity(0.05)))
                                                )
                                        }
                                        // Favorite button
                                        Button(action: {
                                            feedbackMessageId = UUID()
                                            let isAlreadyFavorite = learningStateManager.isFavorite(entry.id)
                                            learningStateManager.toggleFavorite(entry.id)
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                feedbackMessage = isAlreadyFavorite ? NSLocalizedString("removed_from_favorites", comment: "") : NSLocalizedString("added_to_favorites", comment: "")
                                            }
                                            withAnimation(.spring()) {}
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                feedbackMessage = nil
                                            }
                                        }) {
                                            Image(systemName: learningStateManager.isFavorite(entry.id) ? "star.fill" : "star")
                                                .font(.system(size: 16, weight: .medium))
                                                .frame(width: 36, height: 36)
                                                .foregroundColor(.primary)
                                                .background(
                                                    Circle()
                                                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                                                        .background(Circle().fill(Color.primary.opacity(0.05)))
                                                )
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                        ) {
                            VStack(alignment: .leading, spacing: 20) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("word_translation")
                                        .font(.headline)
                                    Text(retrieveTranslation(from: entry.translations, lang: selectedLanguage))
                                        .italic()
                                        .font(.title3)
                                }
                                
                                let forms = entry.forms ?? []
                                if !forms.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("word_forms")
                                            .font(.headline)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            ForEach(Array(forms.enumerated()), id: \.offset) { index, form in
                                                Button(action: {
                                                    audioPlayerHelper.playWordForm(entryId: entry.id, index: index + 1)
                                                }) {
                                                    HStack(spacing: 6) {
                                                        Image(systemName: "speaker.wave.2.fill")
                                                            .imageScale(.small)
                                                            .foregroundColor(.secondary)
                                                            .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.firstTextBaseline] }
                                                            .offset(y: 1)
                                                        Text(form.form)
                                                            .lineLimit(1)
                                                            .truncationMode(.tail)
                                                            .minimumScaleFactor(0.8)
                                                            .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
                                                    }
                                                    .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                                    .background(Color.primary.opacity(0.05))
                                                    .cornerRadius(8)
                                                    .foregroundColor(.primary)
                                                    .font(.system(size: 18))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                                
                                if !entry.examples.isEmpty {
                                    VStack(alignment: .leading, spacing: 20) {
                                        Text("word_examples")
                                            .font(.headline)
                                        
                                        ForEach(Array(entry.examples.enumerated()), id: \.offset) { i, example in
                                            HStack(alignment: .top, spacing: 8) {
                                                Button(action: {
                                                    playExampleAudio(exampleText: example.text, index: i + 1)
                                                }) {
                                                    Image(systemName: "speaker.wave.2.fill")
                                                        .foregroundColor(.secondary)
                                                }
                                                .padding(.top, 2)
                                                
                                                TappableText(
                                                    text: example.text,
                                                    tappables: extractTappables(from: example.text),
                                                    font: UIFont.systemFont(ofSize: 20)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 40)
                            .padding()
                            .sheet(item: $selectedEntry) { entry in
                                if let categoryId = wordService.categoryIdByWordId(entry.id) {
                                    WordCardView(entry: entry, categoryId: categoryId.uuidString, wordService: wordService, learningStateManager: learningStateManager, audioPlayerHelper: audioPlayerHelper)
                                }
                            }
                            .confirmationDialog("choose_word_title", isPresented: $showingSelectionSheet, titleVisibility: .visible) {
                                ForEach(multipleEntries, id: \.id) { entry in
                                    Button("\(entry.word) – \(retrieveTranslation(from: entry.translations, lang: selectedLanguage))") {
                                        selectedEntry = entry
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
        }
        .overlay(
            Group {
                if let message = feedbackMessage {
                    Text(message)
                        .id(feedbackMessageId)
                        .font(.callout)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.regularMaterial)
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 60)
                        .transition(.opacity)
                }
            },
            alignment: .bottom
        )
        
        func playWordAudio() {
            audioPlayerHelper.playAudio(entryId: entry.id)
        }
        
        func playExampleAudio(exampleText: String, index: Int) {
            audioPlayerHelper.playExample(entryId: entry.id, exampleIndex: index)
        }
        
        func extractTappables(from text: String) -> [String: () -> Void] {
            var tappables: [String: () -> Void] = [:]
            let words = text.split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters) }
            let allSelfWords = [entry.word.lowercased()] + (entry.forms ?? []).map { $0.form.lowercased() }
            let allSelfComponents = Set(allSelfWords.flatMap { $0.split(separator: " ").map(String.init) })
            
            var i = 0
            while i < words.count {
                var matchFound = false
                for j in stride(from: words.count, to: i, by: -1) {
                    let phrase = words[i..<j].map { $0.trimmingCharacters(in: .punctuationCharacters) }.joined(separator: " ")
                    let lowerPhrase = phrase.lowercased()
                    let phraseWords = Set(lowerPhrase.split(separator: " ").map(String.init))
                    
                    if allSelfWords.contains(lowerPhrase) || !phraseWords.isDisjoint(with: allSelfComponents) {
                        continue
                    }
                    
                    let entries = wordService.wordsByStringConsideringArticles(phrase)
                    if !entries.isEmpty {
                        if hideLinksToKnownWords && entries.allSatisfy({ learningStateManager.isKnownOrHidden(id: $0.id) }) {
                            continue
                        }
                        if entries.count == 1 {
                            tappables[phrase] = { selectedEntry = entries[0] }
                        } else {
                            tappables[phrase] = {
                                multipleEntries = entries
                                showingSelectionSheet = true
                            }
                        }
                        i = j
                        matchFound = true
                        break
                    }
                }
                
                if !matchFound {
                    let single = words[i].trimmingCharacters(in: .punctuationCharacters)
                    let lowerSingle = single.lowercased()
                    if !allSelfWords.contains(lowerSingle) && !allSelfComponents.contains(lowerSingle) {
                        let entries = wordService.wordsByStringConsideringArticles(single)
                        if !entries.isEmpty {
                            if hideLinksToKnownWords && entries.allSatisfy({ learningStateManager.isKnownOrHidden(id: $0.id) }) {
                                // Skip adding tappable
                            } else {
                                if entries.count == 1 {
                                    tappables[single] = { selectedEntry = entries[0] }
                                } else {
                                    tappables[single] = {
                                        multipleEntries = entries
                                        showingSelectionSheet = true
                                    }
                                }
                            }
                        }
                    }
                    i += 1
                }
            }
            
            return tappables
        }
    }
}
