//
//  MainQueueScrollViewController.swift
//  test-mainqueue-scroll-demo
//
//  Created by Codex on 2026/6/1.
//

import QuartzCore
import UIKit

final class MainQueueScrollViewController: UIViewController {

    private enum UpdatePolicy: Int {
        case immediate
        case deferWhileScrolling
    }

    private struct FeedItem {
        let title: String
        let subtitle: String
        let version: Int
    }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let fpsLabel = UILabel()
    private let stateLabel = UILabel()
    private let logTextView = UITextView()
    private let policyControl = UISegmentedControl(items: ["立即刷新", "滑动后合并"])
    private let stressSwitch = UISwitch()
    private let producerButton = UIButton(type: .system)
    private let oneShotButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)

    private let producerQueue = DispatchQueue(label: "com.huchu.mainqueue-scroll.producer", qos: .userInitiated)
    private var producerTimer: DispatchSourceTimer?
    private var displayLink: CADisplayLink?
    private var displayFrameCount = 0
    private var displayLastTimestamp = CACurrentMediaTime()
    private var items: [FeedItem] = []
    private var pendingVersion: Int?
    private var updateVersion = 0
    private var isProducing = false
    private var burnSink = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Main Queue Scroll"
        view.backgroundColor = .systemBackground
        configureUI()
        reloadItems(version: 0)
        startFPSMonitor()
        startProducer()
        appendLog("后台任务已启动。先保持“立即刷新 + 主线程重活”，然后持续拖动列表观察 FPS 和日志。")
    }

    deinit {
        producerTimer?.cancel()
        displayLink?.invalidate()
    }

    private func configureUI() {
        policyControl.selectedSegmentIndex = UpdatePolicy.immediate.rawValue
        policyControl.addTarget(self, action: #selector(policyChanged), for: .valueChanged)

        stressSwitch.isOn = true
        stressSwitch.addTarget(self, action: #selector(stressChanged), for: .valueChanged)

        fpsLabel.font = .monospacedSystemFont(ofSize: 14, weight: .semibold)
        fpsLabel.textColor = .systemGreen
        fpsLabel.text = "FPS --"

        stateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        stateLabel.textColor = .secondaryLabel
        stateLabel.numberOfLines = 0
        stateLabel.text = "policy=立即刷新, stress=ON"

        configureButton(producerButton, title: "停止后台")
        configureButton(oneShotButton, title: "手动提交")
        configureButton(clearButton, title: "清空日志")
        producerButton.addTarget(self, action: #selector(toggleProducer), for: .touchUpInside)
        oneShotButton.addTarget(self, action: #selector(runOneShotUpdate), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearLogs), for: .touchUpInside)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 72
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        logTextView.translatesAutoresizingMaskIntoConstraints = false
        logTextView.isEditable = false
        logTextView.alwaysBounceVertical = true
        logTextView.backgroundColor = .secondarySystemBackground
        logTextView.textColor = .label
        logTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logTextView.layer.cornerRadius = 8
        logTextView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)

        let stressRow = UIStackView(arrangedSubviews: [
            label("主线程重活", font: .systemFont(ofSize: 14, weight: .semibold), color: .label),
            stressSwitch,
            fpsLabel
        ])
        stressRow.axis = .horizontal
        stressRow.alignment = .center
        stressRow.spacing = 10

        let buttonRow = UIStackView(arrangedSubviews: [producerButton, oneShotButton, clearButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.spacing = 8

        let headerStack = UIStackView(arrangedSubviews: [
            policyControl,
            stressRow,
            stateLabel,
            buttonRow
        ])
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .vertical
        headerStack.spacing = 10

        view.addSubview(headerStack)
        view.addSubview(tableView)
        view.addSubview(logTextView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            logTextView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 10),
            logTextView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            logTextView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            logTextView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -12),
            logTextView.heightAnchor.constraint(equalToConstant: 155)
        ])
    }

    private func configureButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = .tertiarySystemFill
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
    }

    private func label(_ text: String, font: UIFont, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        return label
    }

    private func reloadItems(version: Int) {
        items = (0..<600).map { index in
            FeedItem(
                title: "Row \(index)  data version \(version)",
                subtitle: "持续滑动时，后台线程提交到主队列的刷新可能穿插执行。index=\(index)",
                version: version
            )
        }
        tableView.reloadData()
    }

    private func startFPSMonitor() {
        let link = CADisplayLink(target: self, selector: #selector(displayLinkTick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func startProducer() {
        guard producerTimer == nil else { return }

        let timer = DispatchSource.makeTimerSource(queue: producerQueue)
        timer.schedule(deadline: .now() + 1.0, repeating: .milliseconds(900), leeway: .milliseconds(80))
        timer.setEventHandler { [weak self] in
            self?.produceBackgroundUpdate(reason: "timer")
        }
        timer.resume()
        producerTimer = timer
        isProducing = true
        producerButton.setTitle("停止后台", for: .normal)
    }

    private func stopProducer() {
        producerTimer?.cancel()
        producerTimer = nil
        isProducing = false
        producerButton.setTitle("启动后台", for: .normal)
    }

    private func produceBackgroundUpdate(reason: String) {
        let enqueueTime = CACurrentMediaTime()
        let nextVersion = updateVersion + 1
        updateVersion = nextVersion

        DispatchQueue.main.async { [weak self] in
            self?.handleMainQueueUpdate(version: nextVersion, reason: reason, enqueueTime: enqueueTime)
        }
    }

    private func handleMainQueueUpdate(version: Int, reason: String, enqueueTime: CFTimeInterval) {
        let policy = UpdatePolicy(rawValue: policyControl.selectedSegmentIndex) ?? .immediate
        let duringScroll = tableView.isDragging || tableView.isDecelerating || tableView.isTracking
        let mode = RunLoop.current.currentMode?.rawValue ?? "nil"
        let queueDelay = (CACurrentMediaTime() - enqueueTime) * 1000.0

        if policy == .deferWhileScrolling && duringScroll {
            pendingVersion = version
            appendLog("cache v\(version) reason=\(reason) mode=\(mode) duringScroll=true delay=\(format(queueDelay))ms")
            return
        }

        applyUpdate(version: version, reason: reason, duringScroll: duringScroll, mode: mode, queueDelay: queueDelay)
    }

    private func applyUpdate(
        version: Int,
        reason: String,
        duringScroll: Bool,
        mode: String,
        queueDelay: Double
    ) {
        let start = CACurrentMediaTime()

        if stressSwitch.isOn {
            burnMainThread(milliseconds: 70)
        }

        reloadItems(version: version)
        let cost = (CACurrentMediaTime() - start) * 1000.0
        appendLog("apply v\(version) reason=\(reason) mode=\(mode) duringScroll=\(duringScroll) delay=\(format(queueDelay))ms mainCost=\(format(cost))ms")
    }

    private func applyPendingUpdateIfNeeded(source: String) {
        guard let version = pendingVersion else { return }

        pendingVersion = nil
        let mode = RunLoop.current.currentMode?.rawValue ?? "nil"
        applyUpdate(version: version, reason: source, duringScroll: false, mode: mode, queueDelay: 0)
    }

    private func burnMainThread(milliseconds: Double) {
        let end = CACurrentMediaTime() + milliseconds / 1000.0
        var value = burnSink
        while CACurrentMediaTime() < end {
            value += sin(value + 0.13)
            if value > 10_000 {
                value = value.truncatingRemainder(dividingBy: 97)
            }
        }
        burnSink = value
    }

    private func appendLog(_ text: String) {
        let line = "\(timestamp())  \(text)\n"
        logTextView.text.append(line)
        logTextView.scrollRangeToVisible(NSRange(location: max(logTextView.text.count - 1, 0), length: 1))
        print(line, terminator: "")
    }

    private func timestamp() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }

    private func format(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func refreshStateLabel() {
        let policy = UpdatePolicy(rawValue: policyControl.selectedSegmentIndex) ?? .immediate
        let policyText = policy == .immediate ? "立即刷新" : "滑动后合并"
        stateLabel.text = "policy=\(policyText), stress=\(stressSwitch.isOn ? "ON" : "OFF"), dragging=\(tableView.isDragging), decelerating=\(tableView.isDecelerating), pending=\(pendingVersion.map(String.init) ?? "nil")"
    }

    @objc private func displayLinkTick(_ link: CADisplayLink) {
        displayFrameCount += 1
        let now = link.timestamp
        let elapsed = now - displayLastTimestamp
        guard elapsed >= 1.0 else { return }

        let fps = Double(displayFrameCount) / elapsed
        fpsLabel.text = "FPS \(Int(round(fps)))"
        fpsLabel.textColor = fps < 50 ? .systemRed : .systemGreen
        displayFrameCount = 0
        displayLastTimestamp = now
        refreshStateLabel()
    }

    @objc private func toggleProducer() {
        if isProducing {
            stopProducer()
            appendLog("后台任务已停止")
        } else {
            startProducer()
            appendLog("后台任务已启动")
        }
    }

    @objc private func runOneShotUpdate() {
        producerQueue.async { [weak self] in
            self?.produceBackgroundUpdate(reason: "manual")
        }
    }

    @objc private func clearLogs() {
        logTextView.text = ""
        appendLog("日志已清空")
    }

    @objc private func policyChanged() {
        pendingVersion = nil
        refreshStateLabel()
        appendLog("切换策略：\(policyControl.selectedSegmentIndex == 0 ? "立即刷新" : "滑动后合并")")
    }

    @objc private func stressChanged() {
        refreshStateLabel()
        appendLog("主线程重活：\(stressSwitch.isOn ? "ON" : "OFF")")
    }
}

extension MainQueueScrollViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = items[indexPath.row]

        var configuration = UIListContentConfiguration.subtitleCell()
        configuration.text = item.title
        configuration.secondaryText = item.subtitle
        configuration.textProperties.font = .systemFont(ofSize: 15, weight: .semibold)
        configuration.secondaryTextProperties.font = .systemFont(ofSize: 12, weight: .regular)
        configuration.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = configuration
        cell.backgroundColor = item.version.isMultiple(of: 2) ? .systemBackground : .secondarySystemBackground
        return cell
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        refreshStateLabel()
        appendLog("scroll begin mode=\(RunLoop.current.currentMode?.rawValue ?? "nil")")
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        refreshStateLabel()
        appendLog("drag end decelerate=\(decelerate)")
        if !decelerate {
            applyPendingUpdateIfNeeded(source: "dragEnd")
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        refreshStateLabel()
        appendLog("deceleration end")
        applyPendingUpdateIfNeeded(source: "decelerationEnd")
    }
}
