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
        layer.frame = bounds

        // ✅ clave: que el layer se redimensione con el view
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer.needsDisplayOnBoundsChange = true

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

    // Tu método: lo dejamos, suma
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        playerLayer?.frame = bounds
    }

    // ✅ más confiable en screensavers
    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }

    // ✅ cubre casos donde layout no dispara como esperás
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        playerLayer?.frame = bounds
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
