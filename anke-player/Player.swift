import UIKit
import AVFoundation

// MARK: - AudioPlayer

class AudioPlayer: NSObject {
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?

    var onReadyToPlay: ((Float) -> Void)?
    var onBufferingUpdate: ((Float) -> Void)?
    var onBufferingFinished: (() -> Void)?
    var onProgressUpdate: ((Float) -> Void)?
    var onPlaybackEnded: (() -> Void)?

    var isPlaying = false

    override init() {
        super.init()
        configureAudioSession()
    }
    
    func resetPlayer() {
        guard let currentItem = playerItem else { return }
        // 移除旧观察者，释放资源
        currentItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
        currentItem.removeObserver(self, forKeyPath: "status")
        currentItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
        
        // 重新创建playerItem和player
        if let urlAsset = currentItem.asset as? AVURLAsset {
            setupPlayer(with: urlAsset.url)
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("[AudioPlayer] AVAudioSession配置成功")
        } catch {
            print("[AudioPlayer] AVAudioSession配置失败: \(error)")
        }
    }

    func setupPlayer(with url: URL) {
        let item = AVPlayerItem(url: url)
        self.playerItem = item
        self.player = AVPlayer(playerItem: item)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinishPlaying),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: item)

        item.addObserver(self, forKeyPath: "loadedTimeRanges", options: [.new, .initial], context: nil)
        item.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [.new], context: nil)

        addPeriodicTimeObserver()
    }

    @objc private func playerDidFinishPlaying() {
        print("[AudioPlayer] 播放完成")
        isPlaying = false
        onPlaybackEnded?()
    }

    private func addPeriodicTimeObserver() {
        guard let player = player else { return }
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600),
                                                      queue: .main) { [weak self] time in
            guard let self = self,
                  let duration = self.playerItem?.duration.seconds,
                  duration > 0 else { return }
            let progress = Float(time.seconds / duration)
            print("[AudioPlayer] 播放进度更新: 当前时间=\(time.seconds)s, 进度=\(progress)")
            self.onProgressUpdate?(progress)
        }
    }

    func play() {
        guard let player = player else { return }
        player.play()
        isPlaying = true
        print("[AudioPlayer] play() 调用")
    }

    func pause() {
        player?.pause()
        isPlaying = false
        print("[AudioPlayer] pause() 调用")
    }

    func seekToTime(seconds: Float, completion: (() -> Void)? = nil) {
        guard let player = player else { return }
        let time = CMTime(seconds: Double(seconds), preferredTimescale: 600)
        print("[AudioPlayer] 准备seek到时间: \(seconds)s")
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            print("[AudioPlayer] seek完成, finished = \(finished)")
            if self.isPlaying {
                player.play()
                print("[AudioPlayer] seek后继续播放")
            }
            completion?()
        }
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard let item = object as? AVPlayerItem else { return }

        if keyPath == "loadedTimeRanges" {
            if let timeRange = item.loadedTimeRanges.first?.timeRangeValue {
                let bufferedTime = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration)
                let totalTime = CMTimeGetSeconds(item.duration)
                if totalTime > 0 {
                    let progress = Float(bufferedTime / totalTime)
                    print("[AudioPlayer] 缓冲进度更新: 缓冲时长=\(bufferedTime)s, 总时长=\(totalTime)s, 进度=\(progress)")
                    onBufferingUpdate?(progress)
                }
            }
        } else if keyPath == "status" {
            if item.status == .readyToPlay {
                let duration = Float(CMTimeGetSeconds(item.duration))
                print("[AudioPlayer] 播放状态 readyToPlay, 总时长: \(duration)s")
                onReadyToPlay?(duration)
            }
        } else if keyPath == "playbackLikelyToKeepUp" {
            let likely = item.isPlaybackLikelyToKeepUp
            print("[AudioPlayer] isPlaybackLikelyToKeepUp = \(likely)")
            if likely {
                onBufferingFinished?()
            }
        }
    }
}
