//
//  ViewController.swift
//  test-combine
//
//  Created by huchu on 2026/5/13.
//

import UIKit
import Combine

final class ViewController: UIViewController {

    private let viewModel = CombineLessonViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let introLabel = UILabel()
    private let inputTitleLabel = UILabel()
    private let usernameTextField = UITextField()
    private let characterCountLabel = UILabel()
    private let validationLabel = UILabel()
    private let stableInputLabel = UILabel()

    private let agreementRow = UIStackView()
    private let agreementLabel = UILabel()
    private let agreementSwitch = UISwitch()

    private let searchButton = UIButton(type: .system)
    private let tapCountLabel = UILabel()

    private let resultTitleLabel = UILabel()
    private let resultTextView = UITextView()

    private let logTitleLabel = UILabel()
    private let logTextView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewModel()
        bindUserInput()
    }

    // MARK: - View Setup

    private func setupView() {
        title = "Combine Learning Lab"
        view.backgroundColor = UIColor(red: 0.97, green: 0.96, blue: 0.93, alpha: 1.0)
        //translatesAutoresizingMaskIntoConstraints，不要让系统替这两个 view 自动生成约束，因为我们要自己写 Auto Layout 约束。
        //true：系统会根据 view 的 frame + autoresizingMask 自动生成一组约束
        //false：系统不帮你生成，约束完全由你自己提供
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill

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

        introLabel.numberOfLines = 0
        introLabel.font = .systemFont(ofSize: 16, weight: .medium)
        introLabel.textColor = UIColor(red: 0.20, green: 0.19, blue: 0.18, alpha: 1.0)
        introLabel.text = """
        这个页面把 Combine 最常见的几件事串在一起：
        1. 输入框文字通过 Publisher 往外发
        2. debounce / removeDuplicates 处理输入噪音
        3. CombineLatest 决定按钮是否可点
        4. 按钮点击通过 Subject 触发异步“请求”
        """

        inputTitleLabel.text = "1. 输入用户名，观察数据流"
        inputTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        inputTitleLabel.textColor = UIColor(red: 0.16, green: 0.15, blue: 0.13, alpha: 1.0)

        usernameTextField.borderStyle = .roundedRect
        usernameTextField.placeholder = "输入至少 2 个字符，试试输入 combine 或 error"
        usernameTextField.font = .systemFont(ofSize: 16)
        usernameTextField.backgroundColor = .white
        usernameTextField.clearButtonMode = .whileEditing

        configureSecondaryLabel(characterCountLabel)
        configureSecondaryLabel(validationLabel)
        configureSecondaryLabel(stableInputLabel)

        agreementRow.axis = .horizontal
        agreementRow.alignment = .center
        agreementRow.spacing = 12

        agreementLabel.text = "2. 勾选后才允许搜索，这里用来演示 CombineLatest"
        agreementLabel.numberOfLines = 0
        agreementLabel.font = .systemFont(ofSize: 15)
        agreementLabel.textColor = UIColor(red: 0.30, green: 0.28, blue: 0.24, alpha: 1.0)

        agreementRow.addArrangedSubview(agreementLabel)
        agreementRow.addArrangedSubview(agreementSwitch)

        searchButton.configuration = .filled()
        searchButton.configuration?.title = "3. 点击按钮触发 PassthroughSubject"
        searchButton.configuration?.cornerStyle = .large
        searchButton.isEnabled = false

        tapCountLabel.font = .systemFont(ofSize: 14, weight: .medium)
        tapCountLabel.textColor = UIColor(red: 0.52, green: 0.33, blue: 0.17, alpha: 1.0)

        resultTitleLabel.text = "4. 结果区"
        resultTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        resultTitleLabel.textColor = UIColor(red: 0.16, green: 0.15, blue: 0.13, alpha: 1.0)

        configureTextView(resultTextView)

        logTitleLabel.text = "5. 事件日志"
        logTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        logTitleLabel.textColor = UIColor(red: 0.16, green: 0.15, blue: 0.13, alpha: 1.0)

        configureTextView(logTextView)

        let overviewCard = makeCard(with: [introLabel])
        let inputCard = makeCard(with: [
            inputTitleLabel,
            usernameTextField,
            characterCountLabel,
            validationLabel,
            stableInputLabel,
            agreementRow,
            searchButton,
            tapCountLabel
        ])
        let resultCard = makeCard(with: [resultTitleLabel, resultTextView])
        let logCard = makeCard(with: [logTitleLabel, logTextView])

        NSLayoutConstraint.activate([
            usernameTextField.heightAnchor.constraint(equalToConstant: 44),
            searchButton.heightAnchor.constraint(equalToConstant: 48),
            resultTextView.heightAnchor.constraint(equalToConstant: 160),
            logTextView.heightAnchor.constraint(equalToConstant: 210)
        ])

        [overviewCard, inputCard, resultCard, logCard].forEach(contentStack.addArrangedSubview)
    }

    private func configureSecondaryLabel(_ label: UILabel) {
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15)
        label.textColor = UIColor(red: 0.30, green: 0.28, blue: 0.24, alpha: 1.0)
    }

    private func configureTextView(_ textView: UITextView) {
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.layer.cornerRadius = 14
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor(red: 0.83, green: 0.79, blue: 0.72, alpha: 1.0).cgColor
        textView.backgroundColor = UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1.0)
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
    }

    private func makeCard(with arrangedSubviews: [UIView]) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.cornerCurve = .continuous
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 12
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill

        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.$characterCountText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.characterCountLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.$validationText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.validationLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.$stableInputText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.stableInputLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.$tapCountText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.tapCountLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.$isSearchButtonEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] isEnabled in
                self?.searchButton.isEnabled = isEnabled
            }
            .store(in: &cancellables)

        viewModel.$resultText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.resultTextView.text = text
            }
            .store(in: &cancellables)

        viewModel.$eventLogText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.logTextView.text = text
            }
            .store(in: &cancellables)
    }

    private func bindUserInput() {
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: usernameTextField)
            .compactMap { ($0.object as? UITextField)?.text }
            .sink { [weak self] text in
                self?.viewModel.usernameInput.send(text)
            }
            .store(in: &cancellables)

        agreementSwitch.addTarget(self, action: #selector(agreementChanged(_:)), for: .valueChanged)
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func agreementChanged(_ sender: UISwitch) {
        viewModel.agreementInput.send(sender.isOn)
    }

    @objc private func searchButtonTapped() {
        viewModel.searchTapped.send(())
    }
}
