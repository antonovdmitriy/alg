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
    @State private var uiImage: UIImage? = nil
    @State private var isLoading = false

    var body: some View {
        ZStack {
            gradientBackground

            VStack {
                Spacer()
                Text(entry.word)
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
                AnimatedAuroraView()
                    .ignoresSafeArea()
            } else {
                AnimatedGradientView()
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

// MARK: - AnimatedGradientView
struct AnimatedGradientView: View {
    @State private var animate = false
    private let gradientColors1 = [Color.purple, Color.blue]
    private let gradientColors2 = [Color.blue, Color.purple]
    private let animationDuration: Double = 4.0

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: animate ? gradientColors2 : gradientColors1),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.linear(duration: animationDuration).repeatForever(autoreverses: true), value: animate)
        .onAppear {
            animate = true
        }
    }
}

struct AnimatedAuroraView: View {
    @State private var animate = false
    @State private var selectedColors: ([Color], [Color]) = ([.black], [.black])

    private let colorPalettes: [([Color], [Color])] = [
        ([Color.black, Color.green, Color.purple], [Color.black, Color.pink, Color.teal]),
        ([Color.black, Color.cyan, Color.indigo], [Color.black, Color.teal, Color.blue]),
        ([Color.black, Color.pink, Color.mint, Color.purple], [Color.black, Color.purple, Color.indigo]),
        ([Color.black, Color.orange, Color.purple, Color.blue], [Color.black, Color.green, Color.indigo])
    ]

    private let animationDuration: Double = 10.0

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: animate ? selectedColors.1 : selectedColors.0),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true), value: animate)
        .onAppear {
            selectedColors = colorPalettes.randomElement() ?? ([Color.black], [Color.black])
            animate = true
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
