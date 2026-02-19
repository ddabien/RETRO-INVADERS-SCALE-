import ScreenSaver
import AVKit
import AVFoundation

final class SpaceInvadersScreensaverView: ScreenSaverView {

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)

        // Un tick suave alcanza (no hace falta 60fps)
        animationTimeInterval = 1.0 / 10.0

        setupVideoPlayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        animationTimeInterval = 1.0 / 10.0

        setupVideoPlayer()
    }

    private func setupVideoPlayer() {
        // NO CAMBIO tus bundles ni la forma de buscar el video
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
        layer.frame = bounds
        layer.videoGravity = .resizeAspectFill

        // Ayuda a que acompañe el tamaño sin depender de callbacks dudosos
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

    // ✅ El fix real del escalado en ScreenSaverView
    override func animateOneFrame() {
        super.animateOneFrame()
        playerLayer?.frame = bounds
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
