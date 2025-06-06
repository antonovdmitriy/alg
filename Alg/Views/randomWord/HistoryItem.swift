import AVFoundation

public struct HistoryItem {
    enum Kind {
        case word(WordEntry, UUID)
        case example(WordEntry, UUID, Int)
    }

    let kind: Kind
}
