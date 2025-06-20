import SwiftUI

struct LanguageLevelSettingsView: View {
    var fromSettings: Bool = true
    var onFinish: (() -> Void)? = nil

    @AppStorage("selectedLanguageLevel") private var selectedLevel = "all"
    @AppStorage("includeLowerLevels") private var includeLowerLevels = true
    
    @Environment(\.dismiss) private var dismiss
    
    private let levels = [
        ("all", NSLocalizedString("language_level_all_option", comment: "")),
        ("a1", "A1"),
        ("a2", "A2"),
        ("b1", "B1"),
        ("b2", "B2"),
        ("c1", "C1"),
        ("c2", "C2")
    ]
    
    var body: some View {
        Form {
            Section {
                ForEach(levels, id: \.0) { value, label in
                    HStack {
                        Text(label)
                        Spacer()
                        if selectedLevel == value {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLevel = value
                    }
                }
            }
            
            if fromSettings {
                Section {
                    Toggle(NSLocalizedString("language_level_include_lower_levels", comment: ""), isOn: $includeLowerLevels)
                }
            }
        }
        .navigationBarTitle(NSLocalizedString("language_level_title", comment: ""), displayMode: .inline)
        .toolbar {
            Button(NSLocalizedString("language_level_continue_button", comment: "")) {
                if !fromSettings {
                    onFinish?()
                }
                dismiss()
            }
        }
    }
}
