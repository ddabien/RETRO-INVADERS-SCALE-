import ScreenSaver
import AVFoundation

final class SpaceInvadersScreensaverView: ScreenSaverView {

    private var player: AVPlayer?
    private var playerView: PlayerView?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setupVideoPlayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupVideoPlayer()
    }

    private func setupVideoPlayer() {
        guard let videoURL = Bundle(for: type(of: self))
            .url(forResource: "video", withExtension: "mp4")
            ?? Bundle.main.url(forResource: "video", withExtension: "mp4")
        else {
            NSLog("❌ Video no encontrado")
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

        // ✅ Usamos un NSView dedicado que tiene AVPlayerLayer como backing layer
        let pv = PlayerView(frame: bounds)
        pv.autoresizingMask = [.width, .height]
        pv.playerLayer.player = player
        pv.playerLayer.videoGravity = .resizeAspectFill

        addSubview(pv)

        self.player = player
        self.playerView = pv
    }

    // ✅ Iniciamos play AQUÍ, cuando el view ya tiene window (evita black screen en fullscreen)
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        player?.play()
    }

    override func startAnimation() {
        super.startAnimation()
        player?.play()
    }

    override func stopAnimation() {
        super.stopAnimation()
        player?.pause()
    }

    @objc private func restartVideo() {
        player?.seek(to: .zero)
        player?.play()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// ✅ NSView que expone AVPlayerLayer como su backing layer nativo
// Esto es mucho más estable que agregar AVPlayerLayer como sublayer
final class PlayerView: NSView {

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    // makeBackingLayer es el método correcto para decirle a NSView qué CALayer usar
    override func makeBackingLayer() -> CALayer {
        return AVPlayerLayer()
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
}
