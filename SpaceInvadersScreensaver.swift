import ScreenSaver
import AVKit
import AVFoundation
import os.log

@objc(SpaceInvadersScreensaverView)
final class SpaceInvadersScreensaverView: ScreenSaverView {

    private let log = OSLog(subsystem: "com.drpendejoloco.spaceinvaders", category: "ScreenSaver")
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var isPlaybackConfigured = false

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        os_log("init isPreview=%{public}@", log: log, type: .info, String(isPreview))
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        // This saver is video-backed through AVPlayerLayer, so there is no per-frame
        // drawing work to schedule through ScreenSaverView.animateOneFrame().
        animationTimeInterval = 60.0
    }

    override func startAnimation() {
        super.startAnimation()
        os_log("startAnimation isPreview=%{public}@", log: log, type: .info, String(isPreview))

        guard !isPreview else {
            return
        }

        configureVideoPlayerIfNeeded()
        player?.play()
    }

    override func stopAnimation() {
        os_log("stopAnimation", log: log, type: .info)
        tearDownVideoPlayer()
        super.stopAnimation()
    }

    private func configureVideoPlayerIfNeeded() {
        guard !isPlaybackConfigured else {
            return
        }

        // In a .saver, resources are not always visible through Bundle.main.
        let bundlesToTry: [Bundle] = [
            Bundle(for: type(of: self)),
            Bundle.main
        ]

        let videoURL = bundlesToTry
            .compactMap { $0.url(forResource: "video", withExtension: "mp4") }
            .first

        guard let videoURL else {
            os_log("video.mp4 not found", log: log, type: .error)
            bundlesToTry.forEach { os_log("bundle tried: %{public}@", log: log, type: .error, $0.bundlePath) }
            return
        }

        let item = AVPlayerItem(url: videoURL)
        let player = AVQueuePlayer()
        player.isMuted = true
        player.actionAtItemEnd = .none
        player.preventsDisplaySleepDuringVideoPlayback = false

        let looper = AVPlayerLooper(player: player, templateItem: item)

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = bounds
        playerLayer.needsDisplayOnBoundsChange = true
        layer?.addSublayer(playerLayer)

        self.player = player
        self.playerLayer = playerLayer
        self.playerLooper = looper
        isPlaybackConfigured = true
    }

    private func tearDownVideoPlayer() {
        player?.pause()
        playerLooper?.disableLooping()
        playerLooper = nil

        playerLayer?.player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil

        player?.removeAllItems()
        player = nil
        isPlaybackConfigured = false

        NotificationCenter.default.removeObserver(self)
    }

    override func animateOneFrame() {
        // AVPlayerLayer presents video frames with hardware-accelerated playback.
        // Keep this intentionally empty so ScreenSaverView does not do manual work.
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        playerLayer?.frame = bounds
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        playerLayer?.frame = bounds
    }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }

    deinit {
        os_log("deinit", log: log, type: .info)
        tearDownVideoPlayer()
    }
}

