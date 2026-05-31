//
//  ViewController.swift
//  test-multithreading-demo
//
//  Created by Codex on 2026/5/29.
//

import UIKit

final class ViewController: UIViewController {

    private lazy var lab = ThreadingDemoLab { [weak self] message in
        self?.appendLog(message)
    }

    private let logTextView = UITextView()
    private let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "多线程 Demo"
        view.backgroundColor = .systemBackground
        configureUI()
        appendLog("选择一个实验开始。日志也会同步输出到 Xcode 控制台。")
    }

    private func configureUI() {
        let titleLabel = UILabel()
        titleLabel.text = "GCD / Operation / NSThread / 锁 / 死锁"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        let descriptionLabel = UILabel()
        descriptionLabel.text = "每个按钮都会启动一组独立实验，观察线程切换、队列调度、依赖执行、临界区保护和串行队列死锁。"
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0

        let buttonGrid = UIStackView(arrangedSubviews: [
            buttonRow([
                makeButton(title: "运行全部", action: #selector(runAllTapped), style: .primary),
                makeButton(title: "GCD", action: #selector(runGCDTapped), style: .normal)
            ]),
            buttonRow([
                makeButton(title: "Operation", action: #selector(runOperationTapped), style: .normal),
                makeButton(title: "NSThread", action: #selector(runThreadTapped), style: .normal)
            ]),
            buttonRow([
                makeButton(title: "锁对比", action: #selector(runLockTapped), style: .normal),
                makeButton(title: "死锁测试", action: #selector(runDeadlockTapped), style: .normal)
            ]),
            buttonRow([
                makeButton(title: "清空日志", action: #selector(clearLogTapped), style: .destructive)
            ])
        ])
        buttonGrid.axis = .vertical
        buttonGrid.spacing = 10

        logTextView.isEditable = false
        logTextView.alwaysBounceVertical = true
        logTextView.backgroundColor = UIColor.secondarySystemBackground
        logTextView.textColor = .label
        logTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logTextView.layer.cornerRadius = 8
        logTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)

        let contentStack = UIStackView(arrangedSubviews: [
            titleLabel,
            descriptionLabel,
            buttonGrid,
            logTextView
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            logTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 320)
        ])
    }

    private func buttonRow(_ buttons: [UIButton]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        return stack
    }

    private enum ButtonStyle {
        case primary
        case normal
        case destructive
    }

    private func makeButton(title: String, action: Selector, style: ButtonStyle) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)

        switch style {
        case .primary:
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
        case .normal:
            button.backgroundColor = .tertiarySystemFill
            button.setTitleColor(.label, for: .normal)
        case .destructive:
            button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
            button.setTitleColor(.systemRed, for: .normal)
        }

        return button
    }

    private func appendLog(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let timestamp = self.timestampFormatter.string(from: Date())
            let line = "[\(timestamp)] \(message)\n"
            self.logTextView.text.append(line)
            self.logTextView.scrollRangeToVisible(NSRange(location: max(self.logTextView.text.count - 1, 0), length: 1))
            print(line, terminator: "")
        }
    }

    @objc private func runAllTapped() {
        appendLog("==== 运行全部实验 ====")
        lab.runAllDemos()
    }

    @objc private func runGCDTapped() {
        lab.runGCDDemo()
    }

    @objc private func runOperationTapped() {
        lab.runOperationDemo()
    }

    @objc private func runThreadTapped() {
        lab.runNSThreadDemo()
    }

    @objc private func runLockTapped() {
        lab.runLockDemo()
    }

    @objc private func runDeadlockTapped() {
        lab.runSerialQueueDeadlockDemo()
    }

    @objc private func clearLogTapped() {
        logTextView.text = ""
        appendLog("日志已清空。")
    }
}
