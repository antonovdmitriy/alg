import SwiftUI
import AVKit
import AVFoundation

    struct FullScreenVideoPlayer: UIViewControllerRepresentable {
        let player: AVPlayer
        
        func makeUIViewController(context: Context) -> UIViewController {
            let controller = UIViewController()
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.frame = UIScreen.main.bounds
            controller.view.layer.addSublayer(playerLayer)
            
            player.play()
            return controller
        }
        
        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    }
