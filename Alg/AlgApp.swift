//
//  AlgApp.swift
//  Alg
//
//  Created by Dmitrii Antonov on 2025-05-14.
//

import SwiftUI


@main
struct AlgApp: App {
    @StateObject private var visualStyleManager = VisualStyleManager()

    private let dependencies = AppDependencies()
    
    var body: some Scene {
        WindowGroup {
            RootRouterView(wordService: dependencies.wordService)
                .environmentObject(visualStyleManager)
        }
    }
}
