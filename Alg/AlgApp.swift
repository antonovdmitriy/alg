//
//  AlgApp.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-14.
//

import SwiftUI

@main
struct AlgApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            if showSplash {
                LaunchSplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                ContentView()
            }
        }
    }
}
