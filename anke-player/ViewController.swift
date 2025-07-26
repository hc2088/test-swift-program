import UIKit
import AVFoundation



// MARK: - ViewController

class ViewController: UIViewController {
    private let audioPlayer = AudioPlayer()

    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("播放", for: .normal)
        return button
    }()

    private let slider = UISlider()
    private let bufferProgressView = UIProgressView(progressViewStyle: .default)
    private let currentTimeLabel = UILabel()
    private let totalTimeLabel = UILabel()

    private var totalDuration: Float = 0
    private var isSliderDragging = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupUI()
        setupPlayer()
    }

    private func setupUI() {
        bufferProgressView.trackTintColor = .lightGray
        bufferProgressView.progressTintColor = .gray

        slider.minimumTrackTintColor = .blue
        slider.maximumTrackTintColor = .clear

        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        [bufferProgressView, slider, playButton, currentTimeLabel, totalTimeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            bufferProgressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            bufferProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bufferProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            slider.centerYAnchor.constraint(equalTo: bufferProgressView.centerYAnchor),
            slider.leadingAnchor.constraint(equalTo: bufferProgressView.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: bufferProgressView.trailingAnchor),

            currentTimeLabel.topAnchor.constraint(equalTo: bufferProgressView.bottomAnchor, constant: 8),
            currentTimeLabel.leadingAnchor.constraint(equalTo: bufferProgressView.leadingAnchor),

            totalTimeLabel.topAnchor.constraint(equalTo: bufferProgressView.bottomAnchor, constant: 8),
            totalTimeLabel.trailingAnchor.constraint(equalTo: bufferProgressView.trailingAnchor),

            playButton.topAnchor.constraint(equalTo: totalTimeLabel.bottomAnchor, constant: 30),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupPlayer() {
        audioPlayer.onReadyToPlay = { [weak self] duration in
            print("[ViewController] 音频准备好，总时长: \(duration)s")
            self?.totalDuration = duration
            self?.totalTimeLabel.text = self?.formatTime(seconds: duration)
        }

        audioPlayer.onBufferingUpdate = { [weak self] progress in
            guard let self = self else { return }
            print("[ViewController] 缓冲进度更新: \(progress)")
            self.bufferProgressView.progress = progress
        }

        audioPlayer.onProgressUpdate = { [weak self] progress in
            guard let self = self else { return }
            if !self.isSliderDragging {
                self.slider.value = progress
                let current = progress * self.totalDuration
                self.currentTimeLabel.text = self.formatTime(seconds: current)
                print("[ViewController] 播放进度更新: \(current)s")
            }
        }

        audioPlayer.onPlaybackEnded = { [weak self] in
            print("[ViewController] 播放结束")
            guard let self = self else { return }
            self.playButton.setTitle("播放", for: .normal)
            self.isSliderDragging = false
            self.slider.value = 0
            self.bufferProgressView.progress = 0
            self.currentTimeLabel.text = self.formatTime(seconds: 0)
            
            // 重置播放器，确保下次能播放
            self.audioPlayer.resetPlayer()
        }
        
        if let url = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3") {
            audioPlayer.setupPlayer(with: url)
        }
    }

    @objc private func playTapped() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            playButton.setTitle("播放", for: .normal)
        } else {
            audioPlayer.play()
            playButton.setTitle("暂停", for: .normal)
        }
    }

    @objc private func sliderValueChanged() {
        let current = slider.value * totalDuration
        currentTimeLabel.text = formatTime(seconds: current)
        print("[ViewController] 滑块值改变，当前时间: \(current)s")
    }

    @objc private func sliderTouchDown() {
        isSliderDragging = true
        print("[ViewController] 滑块开始拖拽")
    }

    @objc private func sliderTouchUp() {
        let newTime = slider.value * totalDuration
        print("[ViewController] 滑块拖拽结束，准备seek到: \(newTime)s")

        isSliderDragging = false

        // 直接seek，无论缓冲情况，AVPlayer会自动加载未缓冲部分
        audioPlayer.seekToTime(seconds: newTime)
    }

    private func formatTime(seconds: Float) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
