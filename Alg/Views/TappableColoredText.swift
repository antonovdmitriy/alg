//
//  TappableColoredText.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-30.
//

import Foundation
import SwiftUI

struct TappableColoredText: View {
    enum Component {
        case text(String)
        case tappable(String, () -> Void)
    }

    let components: [Component]
    let font: UIFont

    init(
        text: String,
        tappables: [Range<String.Index>: () -> Void],
        font: UIFont
    ) {

        var components: [Component] = []
        var index: String.Index = text.startIndex

        let sortedTappables = tappables.sorted {
            $0.key.lowerBound < $1.key.lowerBound
        }
        for tappable in sortedTappables {

            if tappable.key.lowerBound > index {
                let textRange: Range<String.Index> = index..<tappable.key.lowerBound
                let textSubstring = String(text[textRange])

                components.append(.text(textSubstring))
            }

            let substring = String(text[tappable.key])
            components.append(.tappable(substring, tappable.value))
            index = tappable.key.upperBound
        }

        if index < text.indices.endIndex {
            let textRange = index..<text.indices.endIndex
            let substring = String(text[textRange])
            components.append(.text(substring))
        }

        self.components = components
        self.font = font
    }

    var body: some View {
        components.map { component in
            switch component {
            case .text(let text):
                return SwiftUI.Text(verbatim: text)
            case .tappable(let text, _):
                return SwiftUI.Text(verbatim: text)
                    .foregroundStyle(.primary)
                    .underline()
            }
        }
        .reduce(SwiftUI.Text(""), +)
        .font(.init(self.font))
    }
}

struct TappableText: View {
    let text: String
    let tappables: [String: () -> Void]
    let matches: [Range<String.Index>: () -> Void]
    let font: UIFont

    init(
        text: String,
        tappables: [String: () -> Void],
        font: UIFont
    ) {
        self.text = text
        self.tappables = tappables

        var ranges: [Range<String.Index>: () -> Void] = [:]
        var occupied = Set<String.Index>()

        for (word, action) in tappables {
            var searchStart = text.startIndex

            while searchStart < text.endIndex,
                  let range = text.range(of: word, range: searchStart..<text.endIndex) {

                // Проверяем, не перекрывается ли этот диапазон с уже занятыми символами
                if !occupied.contains(where: { range.contains($0) }) {
                    ranges[range] = action
                    var index = range.lowerBound
                    while index < range.upperBound {
                        occupied.insert(index)
                        index = text.index(after: index)
                    }
                }

                searchStart = range.upperBound
            }
        }

        matches = ranges
        self.font = font
    }

    var body: some View {
        TappableColoredText(text: text, tappables: matches, font: self.font)
            .overlay(LinkTapOverlay(text: text, tappables: matches, font: font))
    }
}

private struct LinkTapOverlay: UIViewRepresentable {
    let text: String
    let tappables: [Range<String.Index>: () -> Void]
    let font: UIFont

    func makeUIView(context: Context) -> LinkTapOverlayView {
        let view = LinkTapOverlayView()
        view.textContainer = context.coordinator.textContainer

        view.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didTapLabel(_:)))
        tapGesture.delegate = context.coordinator
        view.addGestureRecognizer(tapGesture)

        return view
    }

    func updateUIView(_ uiView: LinkTapOverlayView, context: Context) {
        let attributedString = NSAttributedString(string: text, attributes: [.font: font])
        context.coordinator.textStorage = NSTextStorage(attributedString: attributedString)
        context.coordinator.textStorage!.addLayoutManager(context.coordinator.layoutManager)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let overlay: LinkTapOverlay

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        var textStorage: NSTextStorage?

        init(_ overlay: LinkTapOverlay) {
            self.overlay = overlay

            textContainer.lineFragmentPadding = 0
            textContainer.lineBreakMode = .byWordWrapping
            textContainer.maximumNumberOfLines = 0
            layoutManager.addTextContainer(textContainer)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            let location = touch.location(in: gestureRecognizer.view!)
            let result = tappable(at: location)
            return result != nil
        }

        @objc func didTapLabel(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view!)
            guard let result = tappable(at: location) else {
                return
            }

            result()
        }

        private func tappable(at point: CGPoint) -> (() -> Void)? {
            guard !overlay.tappables.isEmpty else {
                return nil
            }

            let indexOfCharacter = layoutManager.characterIndex(
                for: point,
                in: textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )

            let text = overlay.text
            let stringIndex = text.index(text.startIndex, offsetBy: indexOfCharacter)

            return overlay.tappables.first(where: { (tappable) -> Bool in
                tappable.key.contains(stringIndex)
            })?.value
        }
    }
}

private class LinkTapOverlayView: UIView {
    var textContainer: NSTextContainer!

    override func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = bounds.size
    }
}
