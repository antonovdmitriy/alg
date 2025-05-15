//
//  LaunchSplashView.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-16.
//
import SwiftUI
import UIKit

struct LaunchSplashView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var displayedText = ""
    private let fullText = "Älg"
    private let typingSpeed = 0.2

    var body: some View {
        ZStack {
            backgroundView

            Text(displayedText)
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .animation(.easeOut, value: displayedText)
        }
        .onAppear {
            typeText()
        }
    }

    private var backgroundView: some View {
        Group {
            if colorScheme == .dark {
                AnimatedAuroraView()
            } else {
                AnimatedGradientView()
            }
        }
        .ignoresSafeArea()
    }

    private func typeText() {
        displayedText = ""
        for (index, char) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * typingSpeed) {
                displayedText.append(char)
            }
        }
    }
}
