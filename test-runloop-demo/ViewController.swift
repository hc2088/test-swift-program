//
//  ViewController.swift
//  test-runloop-demo
//
//  Created by Codex on 2026/5/24.
//

import UIKit

final class ViewController: UIViewController {

    private let lab = RunLoopThreadLab()
    private let sourceOnlyLab = SourceOnlyLoggerLab()
    private let exitConditionLab = RunLoopExitConditionLab()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let statusLabel = UILabel()
    private let activityLabel = UILabel()
    private let meaningLabel = UILabel()
    private let exitConditionStatusLabel = UILabel()
    private let sourceOnlyStatusLabel = UILabel()
    private let logTextView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindLab()
        lab.startIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || navigationController == nil {
            lab.stop()
            sourceOnlyLab.stop()
        }
    }

    private func setupView() {
        title = "RunLoop Demo"
        view.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1)

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

        [
            makeIntroCard(),
            makeStateCard(),
            makeControlsCard(),
            makeExitConditionCard(),
            makeSourceOnlyLoggerCard(),
            makeLogCard()
        ].forEach(contentStack.addArrangedSubview)
    }

    private func bindLab() {
        lab.onStatusChange = { [weak self] text in
            self?.statusLabel.text = "线程状态：\(text)"
        }

        lab.onStateChange = { [weak self] record in
            self?.activityLabel.text = "当前状态：\(record.description)"
            self?.meaningLabel.text = self?.meaningText(for: record.activity)
        }

        lab.onLog = { [weak self] line in
            self?.appendLog(line)
        }

        sourceOnlyLab.onStatusChange = { [weak self] text in
            self?.sourceOnlyStatusLabel.text = "Source-only 日志线程：\(text)"
        }

        sourceOnlyLab.onLog = { [weak self] line in
            self?.appendLog(line)
        }

        exitConditionLab.onStatusChange = { [weak self] text in
            self?.exitConditionStatusLabel.text = "退出条件实验：\(text)"
        }

        exitConditionLab.onLog = { [weak self] line in
            self?.appendLog(line)
        }
    }

    @objc private func startRunLoopThread() {
        appendLog("主线程点击：启动 worker RunLoop")
        lab.startIfNeeded()
    }

    @objc private func stopRunLoopThread() {
        appendLog("主线程点击：停止 worker RunLoop")
        lab.stop()
    }

    @objc private func source0SignalOnly() {
        appendLog("主线程点击：Source0 只 signal")
        lab.triggerSource0(signalOnly: true)
    }

    @objc private func source0SignalAndWakeUp() {
        appendLog("主线程点击：Source0 signal + wakeUp")
        lab.triggerSource0(signalOnly: false)
    }

    @objc private func sendSource1PortMessage() {
        appendLog("主线程点击：发送 Port 消息(Source1)")
        lab.sendPortMessage()
    }

    @objc private func scheduleWorkerTimer() {
        appendLog("主线程点击：在 worker RunLoop 上安排 Timer")
        lab.scheduleWorkerTimer()
    }

    @objc private func scheduleRunLoopBlock() {
        appendLog("主线程点击：向 worker RunLoop 投递 block")
        lab.scheduleRunLoopBlock()
    }

    @objc private func clearLog() {
        logTextView.text = ""
        appendLog("日志已清空")
    }

    @objc private func runExitConditionCases() {
        appendLog("主线程点击：运行 RunLoop 退出条件实验")
        exitConditionLab.runAllCases()
    }

    @objc private func startSourceOnlyLogger() {
        appendLog("主线程点击：启动 Source-only 日志线程")
        sourceOnlyLab.startIfNeeded()
    }

    @objc private func stopSourceOnlyLogger() {
        appendLog("主线程点击：停止 Source-only 日志线程")
        sourceOnlyLab.stop()
    }

    @objc private func enqueueSourceOnlySignalOnly() {
        appendLog("主线程点击：提交业务日志，只 signal Source0")
        sourceOnlyLab.enqueueDemoEvents(count: 5, wakeUp: false)
    }

    @objc private func enqueueSourceOnlyAndWakeUp() {
        appendLog("主线程点击：提交业务日志，signal Source0 + wakeUp")
        sourceOnlyLab.enqueueDemoEvents(count: 5, wakeUp: true)
    }

    private func makeIntroCard() -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.16, green: 0.19, blue: 0.24, alpha: 1)
        titleLabel.text = "RunLoop 线程实验台"

        let introLabel = UILabel()
        introLabel.numberOfLines = 0
        introLabel.font = .systemFont(ofSize: 15)
        introLabel.textColor = UIColor(red: 0.33, green: 0.38, blue: 0.47, alpha: 1)
        introLabel.text = """
        这个页面把文档里的 runloop.png 拆成可点击实验：
        1. run：worker 线程里的 while + run(mode:before:)
        2. port / Source1：Port 加入 RunLoop，主线程发消息进来
        3. Source0：CFRunLoopSourceSignal + 可选 CFRunLoopWakeUp
        4. Timer：在 worker RunLoop 上安排一个定时器
        5. block：这里特指 CFRunLoopPerformBlock 投递到某个 RunLoop 的任务
        6. observer：观察 6 个状态 Entry / BeforeTimers / BeforeSources / BeforeWaiting / AfterWaiting / Exit
        7. exit condition：验证空 RunLoop、只加 Observer、只加 Source0、只加 Timer 时 run 是否返回
        8. source-only logger：只添加自定义 Source0，不添加 Port，用常驻线程批量写业务日志
        """

        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.numberOfLines = 0
        statusLabel.textColor = UIColor(red: 0.22, green: 0.39, blue: 0.78, alpha: 1)
        statusLabel.text = "线程状态：准备启动..."

        return makeCard(with: [titleLabel, introLabel, statusLabel])
    }

    private func makeStateCard() -> UIView {
        activityLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        activityLabel.numberOfLines = 0
        activityLabel.textColor = UIColor(red: 0.15, green: 0.18, blue: 0.24, alpha: 1)
        activityLabel.text = "当前状态：-"

        meaningLabel.font = .systemFont(ofSize: 14)
        meaningLabel.numberOfLines = 0
        meaningLabel.textColor = UIColor(red: 0.34, green: 0.39, blue: 0.47, alpha: 1)
        meaningLabel.text = "等待 RunLoop 状态变化..."

        let hintLabel = UILabel()
        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.numberOfLines = 0
        hintLabel.textColor = UIColor(red: 0.50, green: 0.54, blue: 0.62, alpha: 1)
        hintLabel.text = """
        观察重点：
        - BeforeTimers：马上检查 Timer
        - BeforeSources：马上处理 Source0 / block
        - BeforeWaiting：这一轮准备休眠
        - AfterWaiting：刚从休眠中醒来
        """

        return makeCard(with: [activityLabel, meaningLabel, hintLabel])
    }

    private func makeControlsCard() -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.18, blue: 0.24, alpha: 1)
        titleLabel.text = "实验按钮"

        let buttons: [(String, Selector)] = [
            ("启动 worker RunLoop", #selector(startRunLoopThread)),
            ("停止 worker RunLoop", #selector(stopRunLoopThread)),
            ("Source0 只 signal", #selector(source0SignalOnly)),
            ("Source0 signal + wakeUp", #selector(source0SignalAndWakeUp)),
            ("发送 Port 消息(Source1)", #selector(sendSource1PortMessage)),
            ("安排一次 Timer", #selector(scheduleWorkerTimer)),
            ("投递一个 RunLoop block", #selector(scheduleRunLoopBlock)),
            ("清空日志", #selector(clearLog))
        ]

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 10

        for pair in stride(from: 0, to: buttons.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 10
            row.distribution = .fillEqually

            for index in pair..<min(pair + 2, buttons.count) {
                let button = makeActionButton(title: buttons[index].0, action: buttons[index].1)
                row.addArrangedSubview(button)
            }
            grid.addArrangedSubview(row)
        }

        let hintLabel = UILabel()
        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.numberOfLines = 0
        hintLabel.textColor = UIColor(red: 0.50, green: 0.54, blue: 0.62, alpha: 1)
        hintLabel.text = """
        建议点击顺序：
        1. 先看启动后自动打印的 Entry / BeforeWaiting / AfterWaiting
        2. 点 Source0 只 signal，观察为什么不会立刻执行
        3. 再点 Source0 signal + wakeUp，看 BeforeSources 和 Source0 perform
        4. 点发送 Port 消息，观察 Source1/Port 回调
        5. 点安排 Timer，观察 BeforeTimers 到 Timer fired
        6. 点投递 block，观察 BeforeSources 和 block 执行
        """

        return makeCard(with: [titleLabel, grid, hintLabel])
    }

    private func makeExitConditionCard() -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.18, blue: 0.24, alpha: 1)
        titleLabel.text = "RunLoop 退出条件实验"

        exitConditionStatusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        exitConditionStatusLabel.numberOfLines = 0
        exitConditionStatusLabel.textColor = UIColor(red: 0.22, green: 0.39, blue: 0.78, alpha: 1)
        exitConditionStatusLabel.text = "退出条件实验：未运行"

        let descLabel = UILabel()
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.numberOfLines = 0
        descLabel.textColor = UIColor(red: 0.50, green: 0.54, blue: 0.62, alpha: 1)
        descLabel.text = """
        这个实验会依次启动临时线程，分别测试：空 RunLoop、只加 Observer、只加 Source0、不唤醒的 Source0、signal+wakeUp 的 Source0、只加 Timer。看日志里的 elapsed：几毫秒返回就是没保住；等到 timeout 或事件触发才说明当前 mode 有可等待对象。
        """

        let button = makeActionButton(title: "运行退出条件实验", action: #selector(runExitConditionCases))
        return makeCard(with: [titleLabel, exitConditionStatusLabel, descLabel, button])
    }

    private func makeSourceOnlyLoggerCard() -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.18, blue: 0.24, alpha: 1)
        titleLabel.text = "Source0 保活：业务日志批量落盘"

        sourceOnlyStatusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        sourceOnlyStatusLabel.numberOfLines = 0
        sourceOnlyStatusLabel.textColor = UIColor(red: 0.22, green: 0.39, blue: 0.78, alpha: 1)
        sourceOnlyStatusLabel.text = "Source-only 日志线程：未启动"

        let descLabel = UILabel()
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.numberOfLines = 0
        descLabel.textColor = UIColor(red: 0.50, green: 0.54, blue: 0.62, alpha: 1)
        descLabel.text = """
        实际场景：主线程产生页面曝光、点击、调试日志等事件，不直接写文件，而是交给一个常驻 worker 线程批量落盘。这个 worker 的 RunLoop 只添加自定义 Source0，不添加 Port。

        观察重点：Source0 只 signal 时，睡着的线程不会立刻醒；signal + wakeUp 后才会执行 callback，把堆积日志一次性写入 Caches。
        """

        let buttons: [(String, Selector)] = [
            ("启动日志线程", #selector(startSourceOnlyLogger)),
            ("停止日志线程", #selector(stopSourceOnlyLogger)),
            ("提交日志只 signal", #selector(enqueueSourceOnlySignalOnly)),
            ("提交日志并 wakeUp", #selector(enqueueSourceOnlyAndWakeUp))
        ]

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 10

        for pair in stride(from: 0, to: buttons.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 10
            row.distribution = .fillEqually

            for index in pair..<min(pair + 2, buttons.count) {
                row.addArrangedSubview(makeActionButton(title: buttons[index].0, action: buttons[index].1))
            }
            grid.addArrangedSubview(row)
        }

        return makeCard(with: [titleLabel, sourceOnlyStatusLabel, descLabel, grid])
    }

    private func makeLogCard() -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.18, blue: 0.24, alpha: 1)
        titleLabel.text = "日志输出"

        logTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logTextView.textColor = UIColor(red: 0.20, green: 0.22, blue: 0.27, alpha: 1)
        logTextView.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1)
        logTextView.layer.cornerRadius = 14
        logTextView.isEditable = false
        logTextView.isScrollEnabled = false
        logTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        logTextView.heightAnchor.constraint(equalToConstant: 360).isActive = true

        return makeCard(with: [titleLabel, logTextView])
    }

    private func makeCard(with views: [UIView]) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 0.88, green: 0.90, blue: 0.95, alpha: 1).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    private func makeActionButton(title: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = UIColor(red: 0.22, green: 0.46, blue: 0.92, alpha: 1)
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 12, bottom: 14, trailing: 12)

        let button = UIButton(type: .system)
        button.configuration = configuration
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func meaningText(for activity: CFRunLoopActivity) -> String {
        switch activity {
        case .entry:
            return "Entry：这一轮 RunLoop 正式开始。"
        case .beforeTimers:
            return "BeforeTimers：马上检查当前 mode 下有没有 ready 的 Timer。"
        case .beforeSources:
            return "BeforeSources：马上处理 Source0，以及投递到这个 RunLoop 的 block 等任务。"
        case .beforeWaiting:
            return "BeforeWaiting：这一轮大部分事情做完了，RunLoop 准备休眠。"
        case .afterWaiting:
            return "AfterWaiting：线程刚从休眠中醒来，准备继续处理事件。"
        case .exit:
            return "Exit：当前这次 run(mode:before:) 结束，或者 RunLoop 被显式 stop。"
        default:
            return "未知状态。"
        }
    }

    private func appendLog(_ line: String) {
        if logTextView.text.isEmpty {
            logTextView.text = line
        } else {
            logTextView.text += "\n\(line)"
        }
        let bottom = NSRange(location: max(logTextView.text.count - 1, 0), length: 1)
        logTextView.scrollRangeToVisible(bottom)
    }
}
