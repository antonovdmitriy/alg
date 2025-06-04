import SwiftUI


@main
struct AlgApp: App {
    @StateObject private var visualStyleManager = VisualStyleManager()

    private let dependencies = AppDependencies()
    
    var body: some Scene {
        WindowGroup {
            RootRouterView(wordService: dependencies.wordService, learningStateManager: dependencies.learningStateManager, audioPlayerHelper: dependencies.audioPlayerHelper)
                .environmentObject(visualStyleManager)
        }
    }
}
