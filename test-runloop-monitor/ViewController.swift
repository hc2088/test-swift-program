//
//  ViewController.swift
//  test-runloop-monitor
//
//  Created by Codex on 2026/5/23.
//

import UIKit
import QuartzCore

final class ViewController: UIViewController {

    private let monitor = RunLoopStallMonitor(timeoutInterval: 0.08)

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let currentActivityLabel = UILabel()
    private let currentMeaningLabel = UILabel()
    private let stallCountLabel = UILabel()
    private let monitorStatusLabel = UILabel()
    private let logTextView = UITextView()

    private var stallCount = 0
    private var isMonitoring = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindMonitor()
        startMonitoringIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || navigationController == nil {
            monitor.stop()
            isMonitoring = false
        }
    }

    private func setupView() {
        title = "RunLoop Stall Monitor"
        view.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 18

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        let introCard = makeIntroCard()
        let stateCard = makeStateCard()
        let controlsCard = makeControlsCard()
        let logCard = makeLogCard()

        [introCard, stateCard, controlsCard, logCard].forEach(contentStack.addArrangedSubview)
    }

    private func bindMonitor() {
        monitor.onActivityChange = { [weak self] _, description in
            self?.currentActivityLabel.text = "当前阶段：\(description)"
            self?.currentMeaningLabel.text = self?.meaningText(for: description)
        }

        monitor.onStallRecord = { [weak self] record in
            DispatchQueue.main.async {
                guard let self else { return }
                self.stallCount += 1
                self.stallCountLabel.text = "疑似卡顿次数：\(self.stallCount)"
                self.appendLog("stall #\(self.stallCount) -> \(RunLoopStallMonitor.activityDescription(record.activity)) \(Int(record.duration * 1000))ms")
                self.appendLog("reason: \(record.reason)")
            }
        }

        monitor.onLog = { [weak self] text in
            DispatchQueue.main.async {
                self?.appendLog(text)
            }
        }
    }

    private func startMonitoringIfNeeded() {
        guard !isMonitoring else { return }
        monitor.start()
        isMonitoring = true
        monitorStatusLabel.text = "监控状态：已启动（阈值 80ms）"
    }

    @objc private func toggleMonitor() {
        if isMonitoring {
            monitor.stop()
            isMonitoring = false
            monitorStatusLabel.text = "监控状态：已停止"
        } else {
            monitor.start()
            isMonitoring = true
            monitorStatusLabel.text = "监控状态：已启动（阈值 80ms）"
        }
    }

    @objc private func blockMain120ms() {
        appendLog("button tapped -> block main 120ms")
        busyLoop(for: 0.12)
    }

    @objc private func blockMain600ms() {
        appendLog("button tapped -> block main 600ms")
        busyLoop(for: 0.6)
    }

    @objc private func layoutStress() {
        appendLog("button tapped -> run 180 layout passes on main")

        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 4
        container.translatesAutoresizingMaskIntoConstraints = false

        for index in 0..<32 {
            let row = UILabel()
            row.numberOfLines = 0
            row.font = .systemFont(ofSize: 12, weight: .medium)
            row.text = "row \(index) - This label is intentionally long to force text layout and Auto Layout work."
            container.addArrangedSubview(row)
        }

        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
        ])

        for _ in 0..<180 {
            container.spacing = .random(in: 2...9)
            container.layoutIfNeeded()
        }

        container.removeFromSuperview()
    }

    @objc private func burstMainQueue() {
        appendLog("button tapped -> enqueue 120 blocks to main queue")
        for index in 0..<120 {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                _ = index * index
                if index == 119 {
                    self.appendLog("main queue burst drained")
                }
            }
        }
    }

    @objc private func clearLog() {
        logTextView.text = ""
        appendLog("log cleared")
    }

    private func busyLoop(for duration: TimeInterval) {
        let deadline = CACurrentMediaTime() + duration
        var value = 0.0
        while CACurrentMediaTime() < deadline {
            value += sqrt(9876.54321)
        }
        if value < 0 {
            print(value)
        }
    }

    private func appendLog(_ text: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let line = "[\(formatter.string(from: Date()))] \(text)"
        if logTextView.text.isEmpty {
            logTextView.text = line
        } else {
            logTextView.text += "\n\(line)"
        }
        let bottom = NSRange(location: max(logTextView.text.count - 1, 0), length: 1)
        logTextView.scrollRangeToVisible(bottom)
    }

    private func meaningText(for description: String) -> String {
        switch description {
        case "AfterWaiting":
            return "主线程刚醒来，准备进入这一轮事件处理。很多卡顿就发生在刚醒来后。"
        case "BeforeSources":
            return "马上处理 Source0 / 主队列任务 / 业务代码。这里最容易被主线程重活卡住。"
        case "BeforeWaiting":
            return "这一轮大部分工作做完了，RunLoop 准备休眠。很多监控把它当作“健康收尾”标记。"
        default:
            return "这个阶段会出现，但主流卡顿监控更关注 AfterWaiting、BeforeSources 和 BeforeWaiting。"
        }
    }

    private func makeIntroCard() -> UIView {
        let introLabel = UILabel()
        introLabel.numberOfLines = 0
        introLabel.font = .systemFont(ofSize: 16, weight: .medium)
        introLabel.textColor = UIColor(red: 0.18, green: 0.22, blue: 0.31, alpha: 1)
        introLabel.text = """
        这个 demo 观察主线程 RunLoop 的 3 个关键阶段：
        1. AfterWaiting：刚被唤醒
        2. BeforeSources：准备处理 Source0 / 主线程任务
        3. BeforeWaiting：这一轮准备休眠

        主流卡顿监控通常盯 AfterWaiting 和 BeforeSources 来判断“主线程刚醒来后是否长时间不推进”，同时把 BeforeWaiting 当作健康收尾点。
        """

        monitorStatusLabel.numberOfLines = 0
        monitorStatusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        monitorStatusLabel.textColor = UIColor(red: 0.22, green: 0.39, blue: 0.78, alpha: 1)
        monitorStatusLabel.text = "监控状态：正在启动..."

        return makeCard(with: [introLabel, monitorStatusLabel])
    }

    private func makeStateCard() -> UIView {
        currentActivityLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        currentActivityLabel.textColor = UIColor(red: 0.15, green: 0.18, blue: 0.24, alpha: 1)
        currentActivityLabel.numberOfLines = 0
        currentActivityLabel.text = "当前阶段：-"

        currentMeaningLabel.font = .systemFont(ofSize: 15)
        currentMeaningLabel.textColor = UIColor(red: 0.34, green: 0.39, blue: 0.47, alpha: 1)
        currentMeaningLabel.numberOfLines = 0
        currentMeaningLabel.text = "等待监控回调..."

        stallCountLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        stallCountLabel.textColor = UIColor(red: 0.66, green: 0.24, blue: 0.20, alpha: 1)
        stallCountLabel.text = "疑似卡顿次数：0"

        return makeCard(with: [currentActivityLabel, currentMeaningLabel, stallCountLabel])
    }

    private func makeControlsCard() -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.18, blue: 0.24, alpha: 1)
        titleLabel.text = "实验按钮"

        let detailLabel = UILabel()
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.textColor = UIColor(red: 0.36, green: 0.40, blue: 0.47, alpha: 1)
        detailLabel.numberOfLines = 0
        detailLabel.text = "建议先点 120ms 和 600ms，观察日志里为什么常常会卡在 AfterWaiting / BeforeSources。"

        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 10

        let buttons: [(String, Selector, UIColor)] = [
            ("阻塞主线程 120ms", #selector(blockMain120ms), UIColor(red: 0.97, green: 0.55, blue: 0.31, alpha: 1)),
            ("阻塞主线程 600ms", #selector(blockMain600ms), UIColor(red: 0.90, green: 0.29, blue: 0.23, alpha: 1)),
            ("主线程布局压力 180 次", #selector(layoutStress), UIColor(red: 0.25, green: 0.53, blue: 0.98, alpha: 1)),
            ("主队列 burst 120 blocks", #selector(burstMainQueue), UIColor(red: 0.40, green: 0.34, blue: 0.86, alpha: 1)),
            ("启动 / 停止监控", #selector(toggleMonitor), UIColor(red: 0.17, green: 0.59, blue: 0.46, alpha: 1)),
            ("清空日志", #selector(clearLog), UIColor(red: 0.30, green: 0.36, blue: 0.46, alpha: 1))
        ]

        buttons.forEach { title, selector, color in
            let button = UIButton(type: .system)
            button.configuration = .filled()
            button.configuration?.title = title
            button.configuration?.baseBackgroundColor = color
            button.configuration?.cornerStyle = .large
            button.heightAnchor.constraint(equalToConstant: 46).isActive = true
            button.addTarget(self, action: selector, for: .touchUpInside)
            buttonStack.addArrangedSubview(button)
        }

        return makeCard(with: [titleLabel, detailLabel, buttonStack])
    }

    private func makeLogCard() -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.18, blue: 0.24, alpha: 1)
        titleLabel.text = "观察日志"

        logTextView.isEditable = false
        logTextView.isScrollEnabled = true
        logTextView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        logTextView.layer.cornerRadius = 16
        logTextView.layer.borderWidth = 1
        logTextView.layer.borderColor = UIColor(red: 0.86, green: 0.90, blue: 0.96, alpha: 1).cgColor
        logTextView.backgroundColor = UIColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1)
        logTextView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        logTextView.heightAnchor.constraint(equalToConstant: 320).isActive = true

        return makeCard(with: [titleLabel, logTextView])
    }

    private func makeCard(with arrangedSubviews: [UIView]) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 22
        card.layer.cornerCurve = .continuous
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 8)

        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 14

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }
}
