import SwiftUI

struct LanguageSelectionView: View {
    var showNextButton: Bool = false
    @AppStorage("preferredTranslationLanguage") private var selectedLanguage = "en"
    @AppStorage("hasSelectedTranslationLanguage") private var hasSelectedLanguage = false
    @State private var isLanguageSelected = true

    var body: some View {
        NavigationView {
            List(languages, id: \.code) { language in
                Button(action: {
                    selectedLanguage = language.code
                    isLanguageSelected = true
                }) {
                    HStack {
                        Text(language.flag)
                        Text(NSLocalizedString(language.localizedNameKey, comment: ""))
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedLanguage == language.code {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text(NSLocalizedString("translation_language_title", comment: "")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showNextButton {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Next") {
                            hasSelectedLanguage = true
                        }
                        .disabled(!isLanguageSelected)
                    }
                }
            }
        }
    }

    private var languages: [(code: String, flag: String, localizedNameKey: String)] {
        [
            ("en", "🇬🇧", "language_english"),
            ("ru", "🇷🇺", "language_russian"),
            ("uk", "🇺🇦", "language_ukrainian"),
            ("pl", "🇵🇱", "language_polish"),
            ("de", "🇩🇪", "language_german"),
            ("fr", "🇫🇷", "language_french"),
            ("it", "🇮🇹", "language_italian"),
            ("es", "🇪🇸", "language_spanish"),
            ("tr", "🇹🇷", "language_turkish"),
            ("fa", "🇮🇷", "language_persian"),
            ("ar", "🇸🇦", "language_arabic"),
            ("hi", "🇮🇳", "language_hindi"),
            ("id", "🇮🇩", "language_indonesian"),
            ("zh", "🇨🇳", "language_chinese"),
            ("so", "🇸🇴", "language_somali"),
            ("sr", "🇷🇸", "language_serbian"),
            ("fi", "🇫🇮", "language_finnish"),
            ("et", "🇪🇪", "language_estonian"),
            ("lt", "🇱🇹", "language_lithuanian"),
            ("lv", "🇱🇻", "language_latvian"),
            ("be", "🇧🇾", "language_belarusian")
        ]
    }
}
