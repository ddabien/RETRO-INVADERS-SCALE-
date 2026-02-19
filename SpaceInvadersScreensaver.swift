import ScreenSaver
import AVKit
import AVFoundation

final class SpaceInvadersScreensaverView: ScreenSaverView {

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setupVideoPlayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupVideoPlayer()
    }

    private func setupVideoPlayer() {
        let bundlesToTry: [Bundle] = [
            Bundle(for: type(of: self)),
            Bundle.main
        ]

        let videoURL = bundlesToTry
            .compactMap { $0.url(forResource: "video", withExtension: "mp4") }
            .first

        guard let videoURL else {
            NSLog("❌ Video no encontrado. Bundles probados:")
            bundlesToTry.forEach { NSLog("   • \($0.bundlePath)") }
            return
        }

        let item = AVPlayerItem(url: videoURL)

        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.actionAtItemEnd = .none

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(restartVideo),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill

        // 👇 clave para que acompañe cambios de tamaño sin depender de callbacks raros
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer.needsDisplayOnBoundsChange = true
        layer.frame = bounds

        wantsLayer = true
        self.layer?.addSublayer(layer)

        self.player = player
        self.playerLayer = layer

        player.play()
    }

    @objc private func restartVideo() {
        player?.seek(to: .zero)
        player?.play()
    }

    // ✅ En ScreenSaverView, esto suele ser más confiable que resizeSubviews(...)
    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }

    // ✅ Cubre cambios de tamaño donde layout no alcanza (preview / cambios raros)
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        playerLayer?.frame = bounds
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
