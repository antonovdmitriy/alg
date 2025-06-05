import SwiftUI
import AVKit

struct SplashView: View {
    
    @State private var selectedSplash: String? = nil
    @Binding var showSplash: Bool
    @AppStorage("lastSplashIndex") private var lastSplashIndex: Int = -1
    private let splashScreenDelay: TimeInterval = 4
    
    var body: some View {
        Group {
            if let splash = selectedSplash {
                FullScreenVideoPlayer(player: AVPlayer(url: Bundle.main.url(forResource: splash, withExtension: "mp4")!))
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear {
            if selectedSplash == nil {
                let splashVideos = ["splash_2", "splash_3"]
                let nextIndex = (lastSplashIndex + 1) % splashVideos.count
                print("Last splash index: \(lastSplashIndex)")
                print("Next splash index: \(nextIndex)")
                lastSplashIndex = nextIndex
                selectedSplash = splashVideos[nextIndex]
                print("Selected splash: \(selectedSplash!)")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + splashScreenDelay) {
                withAnimation {
                    print("SplashView: showSplash flag set to false after delay")
                    showSplash = false
                }
            }
        }
    }
}
