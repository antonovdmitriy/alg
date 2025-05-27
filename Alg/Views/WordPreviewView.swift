//
//  WordPreviewView.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-15.
//

import SwiftUI
import UIKit

struct WordPreviewView: View {
    let entry: WordEntry
    let categoryId: String
    @Binding var overrideText: String?
    @State private var uiImage: UIImage? = nil
    @State private var isLoading = false

    var body: some View {
        ZStack {
            gradientBackground

            VStack {
                Spacer()
                Text(overrideText ?? entry.word)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 1, y: 1)
                    .scaleEffect(1.1)
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var gradientBackground: some View {
        Group {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                AnimatedGradientBackground(palettes: [
                    [Color.black, Color.cyan, Color.indigo],
                    [Color.black, Color.orange, Color.purple, Color.blue],
                    [Color.black, Color.blue, Color.mint],
                    [Color.black, Color.cyan, Color.green],
                    [Color.black, Color.mint, Color.yellow],
                    [Color.black, Color.indigo, Color.teal],
                    [Color.black, Color.blue, Color.pink],
                    [Color.black, Color.orange, Color.mint],
                    [Color.black, Color.purple, Color.cyan],
                    [Color.black, Color.green.opacity(0.6), Color.blue.opacity(0.7), Color.purple.opacity(0.8)],
                    [Color.black, Color.indigo, Color.purple, Color.red.opacity(0.6)],
                    [Color.black, Color.cyan, Color.mint, Color.white.opacity(0.3)],
                    [Color.black, Color.pink.opacity(0.5), Color.purple.opacity(0.5), Color.teal.opacity(0.6)],
                ])
                .ignoresSafeArea()
            } else {
                AnimatedGradientBackground(palettes: [
                    [.pink, .orange, .yellow],
                    [.mint, .teal, .blue],
                    [.cyan, .indigo, .purple],
                    [.green, .mint],
                    [.orange, .red],
                    [.yellow, .green, .blue],
                    [.teal, .cyan],
                    [.purple, .pink, .mint],
                    [.blue, .indigo, .teal],
                    [.orange, .yellow, .mint],
                    [.red, .orange, .pink],
                    [.blue, .purple, .mint],
                    [.mint, .teal, .pink],
                    [.cyan, .green, .yellow],
                    [.orange, .mint, .blue],
                    [.purple, .cyan, .mint],
                    [.indigo, .purple, .red],
                    [.yellow, .cyan, .pink],
                    [.green, .blue, .mint],
                    [.pink, .yellow],
                    [.mint, .green, .yellow],
                    [.indigo, .purple],
                    [.cyan, .blue],
                    [.yellow, .mint, .green],
                    [.teal, .blue],
                    [.green, .cyan],
                    [.indigo, .mint, .teal],
                    [.orange, .indigo],
                    [.cyan, .pink, .mint],
                    [.green, .blue, .mint],
                    [.pink, .purple, .yellow]
                ])
                .ignoresSafeArea()
            }
        }
    }

    private func loadImage() {
        guard !isLoading else { return }
        isLoading = true

        let categoryLower = categoryId.lowercased()
        let entryLower = entry.id.uuidString.lowercased()
        let fileName = "\(entryLower).png"

        let fileManager = FileManager.default
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let directoryURL = cachesURL.appendingPathComponent("images").appendingPathComponent(categoryLower)
        let fileURL = directoryURL.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: fileURL.path) {
            if let image = UIImage(contentsOfFile: fileURL.path) {
                uiImage = image
                isLoading = false
            } else {
                // Failed to load image from file, remove corrupt file and try download
                try? fileManager.removeItem(at: fileURL)
                downloadImage(to: fileURL)
            }
        } else {
            downloadImage(to: fileURL)
        }
    }

    private func downloadImage(to fileURL: URL) {
        let categoryLower = categoryId.lowercased()
        let entryLower = entry.id.uuidString.lowercased()
        let urlString = "https://algaudio.blob.core.windows.net/images/\(categoryLower)/\(entryLower).png"
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                defer { isLoading = false }
                guard let data = data, error == nil, let image = UIImage(data: data) else {
                    return
                }

                do {
                    let directory = fileURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                    try data.write(to: fileURL)
                } catch {
                    // Ignore caching error
                }

                uiImage = image
            }
        }
        task.resume()
    }
}

struct AnimatedGradientBackground: View {
    let palettes: [[Color]]
    let idleDuration: Double
    let transitionDuration: Double

    @State private var selectedColors: [Color]
    @State private var timer: Timer?

    init(palettes: [[Color]], idleDuration: Double = 15.0, transitionDuration: Double = 5.0) {
        self.palettes = palettes
        self.idleDuration = idleDuration
        self.transitionDuration = transitionDuration
        _selectedColors = State(initialValue: palettes.randomElement() ?? [.blue, .purple])
    }

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: selectedColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .onAppear {
            print("[AnimatedGradientBackground] View appeared. Starting gradient timer.")

            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: idleDuration + transitionDuration,
                                         repeats: true) { _ in
                let newColors = palettes.randomElement() ?? selectedColors
                print("[AnimatedGradientBackground] Starting transition. New palette: \(newColors). Duration: \(transitionDuration)s")
                withAnimation(.linear(duration: transitionDuration)) {
                    selectedColors = newColors
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) {
                    print("[AnimatedGradientBackground] Transition completed. Next update in \(idleDuration)s")
                }
            }
        }
        .onDisappear {
            print("[AnimatedGradientBackground] View disappeared. Invalidating timer.")
            timer?.invalidate()
            timer = nil
        }
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView()
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}
