import SwiftUI

struct ExamplesCountSelectionView: View {
    @Binding var selectedCount: Int

    var body: some View {
        List {
            ForEach([-1] + Array(1...10), id: \.self) { number in
                HStack {
                    Text(number == -1 ? NSLocalizedString("settings_examples_all", comment: "") : "\(number)")
                    Spacer()
                    if selectedCount == number {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedCount = number
                }
            }
        }
        .navigationTitle("settings_examples_to_show_count")
    }
}
