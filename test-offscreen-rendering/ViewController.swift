//
//  ViewController.swift
//  test-offscreen-rendering
//
//  Created by Codex on 2026/5/23.
//

import UIKit

final class ViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let statusLabel = UILabel()
    private let animateButton = UIButton(type: .system)

    private var sampleViews: [SampleAnimatable] = []
    private var isAnimatingSamples = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        title = "Offscreen Rendering Lab"
        view.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 18
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
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
        ])

        let introCard = makeIntroCard()
        let roundedClipView = RoundedMaskClipSampleView()
        let shadowView = ShadowSampleView()
        let rasterizedView = RasterizedSampleView()
        let layerMaskView = LayerMaskSampleView()
        sampleViews = [roundedClipView, shadowView, rasterizedView, layerMaskView]

        let roundedCard = makeExampleCard(
            title: "1. 圆角裁剪（cornerRadius + masksToBounds）",
            detail: "最常见的面试版触发条件。这里用圆角卡片裁剪内部彩色内容，便于和普通圆角区分。",
            code: "layer.cornerRadius = 28\nlayer.masksToBounds = true",
            sampleView: roundedClipView
        )

        let shadowCard = makeExampleCard(
            title: "2. 阴影（shadowPath = nil）",
            detail: "给视图加阴影但不提供 shadowPath，Core Animation 需要额外计算阴影轮廓，这类写法经常被当作典型离屏案例。",
            code: "layer.shadowOpacity = 0.28\nlayer.shadowRadius = 18\nlayer.shadowPath = nil",
            sampleView: shadowView
        )

        let rasterizedCard = makeExampleCard(
            title: "3. 光栅化（shouldRasterize）",
            detail: "这是显式要求系统先把当前图层树栅格化成位图，再拿位图去参与后续合成。",
            code: "layer.shouldRasterize = true\nlayer.rasterizationScale = UIScreen.main.scale",
            sampleView: rasterizedView
        )

        let layerMaskCard = makeExampleCard(
            title: "4. 图层蒙版（layer.mask）",
            detail: "这里用一个星形 CAShapeLayer 做 mask。蒙版先决定哪些像素可见，再交给后续合成。",
            code: "let shape = CAShapeLayer()\nview.layer.mask = shape",
            sampleView: layerMaskView
        )

        [introCard, roundedCard, shadowCard, rasterizedCard, layerMaskCard].forEach(contentStack.addArrangedSubview)
    }

    private func makeIntroCard() -> UIView {
        let introLabel = UILabel()
        introLabel.numberOfLines = 0
        introLabel.font = .systemFont(ofSize: 16, weight: .medium)
        introLabel.textColor = UIColor(red: 0.17, green: 0.21, blue: 0.29, alpha: 1)
        introLabel.text = """
        这页把 4 类最常见的离屏渲染场景并排放在一起：
        1. 圆角裁剪（cornerRadius + masksToBounds）
        2. 阴影（shadowPath = nil）
        3. 光栅化（shouldRasterize）
        4. 图层蒙版（layer.mask）

        建议运行后配合 Xcode 的 “Debug > View Debugging > Rendering > Color Offscreen-Rendered” 一起看。
        """

        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 14, weight: .regular)
        statusLabel.textColor = UIColor(red: 0.39, green: 0.44, blue: 0.54, alpha: 1)
        statusLabel.text = "当前样例静止。点击下面按钮后，4 个 sample 会做轻微动画，更容易观察渲染行为。"

        animateButton.configuration = .filled()
        animateButton.configuration?.title = "开始轻微动画"
        animateButton.configuration?.baseBackgroundColor = UIColor(red: 0.22, green: 0.47, blue: 0.98, alpha: 1)
        animateButton.configuration?.cornerStyle = .large
        animateButton.addTarget(self, action: #selector(toggleAnimation), for: .touchUpInside)
        animateButton.heightAnchor.constraint(equalToConstant: 46).isActive = true

        return makeCard(with: [introLabel, statusLabel, animateButton])
    }

    private func makeExampleCard(
        title: String,
        detail: String,
        code: String,
        sampleView: UIView
    ) -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.13, green: 0.16, blue: 0.22, alpha: 1)
        titleLabel.numberOfLines = 0
        titleLabel.text = title

        let detailLabel = UILabel()
        detailLabel.font = .systemFont(ofSize: 15)
        detailLabel.textColor = UIColor(red: 0.33, green: 0.38, blue: 0.46, alpha: 1)
        detailLabel.numberOfLines = 0
        detailLabel.text = detail

        let codeLabel = PaddingLabel()
        codeLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        codeLabel.textColor = UIColor(red: 0.22, green: 0.24, blue: 0.30, alpha: 1)
        codeLabel.numberOfLines = 0
        codeLabel.backgroundColor = UIColor(red: 0.95, green: 0.97, blue: 0.99, alpha: 1)
        codeLabel.layer.cornerRadius = 12
        codeLabel.layer.masksToBounds = true
        codeLabel.text = code

        let sampleShell = UIView()
        sampleShell.translatesAutoresizingMaskIntoConstraints = false
        sampleShell.backgroundColor = UIColor(red: 0.97, green: 0.98, blue: 1.0, alpha: 1)
        sampleShell.layer.cornerRadius = 20
        sampleShell.layer.borderWidth = 1
        sampleShell.layer.borderColor = UIColor(red: 0.86, green: 0.90, blue: 0.96, alpha: 1).cgColor
        sampleShell.heightAnchor.constraint(equalToConstant: 188).isActive = true

        sampleView.translatesAutoresizingMaskIntoConstraints = false
        sampleShell.addSubview(sampleView)

        NSLayoutConstraint.activate([
            sampleView.leadingAnchor.constraint(equalTo: sampleShell.leadingAnchor, constant: 18),
            sampleView.trailingAnchor.constraint(equalTo: sampleShell.trailingAnchor, constant: -18),
            sampleView.topAnchor.constraint(equalTo: sampleShell.topAnchor, constant: 18),
            sampleView.bottomAnchor.constraint(equalTo: sampleShell.bottomAnchor, constant: -18),
        ])

        return makeCard(with: [titleLabel, detailLabel, codeLabel, sampleShell])
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
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
        ])

        return card
    }

    @objc private func toggleAnimation() {
        isAnimatingSamples.toggle()

        if isAnimatingSamples {
            statusLabel.text = "动画已开启。现在你可以更容易在 Xcode 渲染调试里观察这些图层。"
            animateButton.configuration?.title = "停止动画"
        } else {
            statusLabel.text = "当前样例静止。点击下面按钮后，4 个 sample 会做轻微动画，更容易观察渲染行为。"
            animateButton.configuration?.title = "开始轻微动画"
        }

        sampleViews.forEach { $0.setAnimating(isAnimatingSamples) }
    }
}

private protocol SampleAnimatable: AnyObject {
    func setAnimating(_ animating: Bool)
}

private final class PaddingLabel: UILabel {
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 24, height: size.height + 20)
    }
}

private class BaseSampleView: UIView, SampleAnimatable {

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let accentView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        configureBaseLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAnimating(_ animating: Bool) {
        layer.removeAnimation(forKey: "pulse")
        transform = .identity

        guard animating else { return }

        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = -10
        animation.toValue = 10
        animation.duration = 1.4
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "pulse")
    }

    private func configureBaseLayout() {
        backgroundColor = .white

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = UIColor(white: 1, alpha: 0.82)
        subtitleLabel.numberOfLines = 2

        accentView.translatesAutoresizingMaskIntoConstraints = false
        accentView.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        accentView.layer.cornerRadius = 18

        addSubview(accentView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            accentView.widthAnchor.constraint(equalToConstant: 54),
            accentView.heightAnchor.constraint(equalToConstant: 54),
            accentView.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            accentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 22),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: accentView.leadingAnchor, constant: -12),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
        ])
    }
}

private final class RoundedMaskClipSampleView: BaseSampleView {

    private let blobA = UIView()
    private let blobB = UIView()
    private let badge = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "Clip"
        subtitleLabel.text = "圆角裁剪后的内容只能留在圆角容器内部。"

        layer.cornerRadius = 28
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        backgroundColor = UIColor(red: 0.16, green: 0.48, blue: 0.96, alpha: 1)

        blobA.translatesAutoresizingMaskIntoConstraints = false
        blobA.backgroundColor = UIColor(red: 0.99, green: 0.54, blue: 0.31, alpha: 1)
        blobA.layer.cornerRadius = 42

        blobB.translatesAutoresizingMaskIntoConstraints = false
        blobB.backgroundColor = UIColor(red: 0.96, green: 0.86, blue: 0.30, alpha: 1)
        blobB.layer.cornerRadius = 56

        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.font = .systemFont(ofSize: 12, weight: .bold)
        badge.textColor = UIColor(red: 0.15, green: 0.24, blue: 0.54, alpha: 1)
        badge.backgroundColor = .white
        badge.textAlignment = .center
        badge.text = "masksToBounds"
        badge.layer.cornerRadius = 12
        badge.layer.masksToBounds = true

        addSubview(blobA)
        addSubview(blobB)
        addSubview(badge)

        NSLayoutConstraint.activate([
            blobA.widthAnchor.constraint(equalToConstant: 84),
            blobA.heightAnchor.constraint(equalToConstant: 84),
            blobA.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 30),
            blobA.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -10),

            blobB.widthAnchor.constraint(equalToConstant: 112),
            blobB.heightAnchor.constraint(equalToConstant: 112),
            blobB.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 40),
            blobB.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 18),

            badge.heightAnchor.constraint(equalToConstant: 32),
            badge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            badge.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            badge.widthAnchor.constraint(equalToConstant: 126),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ShadowSampleView: BaseSampleView {

    private let innerCard = UIView()
    private let statsRow = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "Shadow"
        subtitleLabel.text = "这张卡有阴影，但没有提供 shadowPath。"

        backgroundColor = UIColor(red: 0.98, green: 0.89, blue: 0.50, alpha: 1)
        layer.cornerRadius = 30

        innerCard.translatesAutoresizingMaskIntoConstraints = false
        innerCard.backgroundColor = UIColor(red: 0.17, green: 0.19, blue: 0.25, alpha: 1)
        innerCard.layer.cornerRadius = 24
        innerCard.layer.shadowColor = UIColor.black.cgColor
        innerCard.layer.shadowOpacity = 0.28
        innerCard.layer.shadowRadius = 18
        innerCard.layer.shadowOffset = CGSize(width: 0, height: 12)

        statsRow.translatesAutoresizingMaskIntoConstraints = false
        statsRow.axis = .horizontal
        statsRow.alignment = .fill
        statsRow.distribution = .fillEqually
        statsRow.spacing = 8

        ["FPS", "CPU", "GPU"].forEach { text in
            let pill = UILabel()
            pill.font = .systemFont(ofSize: 12, weight: .semibold)
            pill.textAlignment = .center
            pill.text = text
            pill.textColor = UIColor(red: 0.20, green: 0.22, blue: 0.28, alpha: 1)
            pill.backgroundColor = UIColor(red: 1.0, green: 0.93, blue: 0.66, alpha: 1)
            pill.layer.cornerRadius = 12
            pill.layer.masksToBounds = true
            statsRow.addArrangedSubview(pill)
        }

        addSubview(innerCard)
        innerCard.addSubview(statsRow)

        NSLayoutConstraint.activate([
            innerCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            innerCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            innerCard.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            innerCard.heightAnchor.constraint(equalToConstant: 68),

            statsRow.leadingAnchor.constraint(equalTo: innerCard.leadingAnchor, constant: 14),
            statsRow.trailingAnchor.constraint(equalTo: innerCard.trailingAnchor, constant: -14),
            statsRow.centerYAnchor.constraint(equalTo: innerCard.centerYAnchor),
            statsRow.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class RasterizedSampleView: BaseSampleView {

    private let badgeRow = UIStackView()
    private let graphLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "Rasterize"
        subtitleLabel.text = "整个复杂图层树会先被压成位图，再参与后续合成。"

        backgroundColor = UIColor(red: 0.27, green: 0.20, blue: 0.63, alpha: 1)
        layer.cornerRadius = 28
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale

        badgeRow.translatesAutoresizingMaskIntoConstraints = false
        badgeRow.axis = .horizontal
        badgeRow.spacing = 8

        ["Chart", "Tags", "Avatar"].forEach { text in
            let badge = UILabel()
            badge.font = .systemFont(ofSize: 12, weight: .semibold)
            badge.text = text
            badge.textAlignment = .center
            badge.textColor = UIColor(red: 0.23, green: 0.18, blue: 0.58, alpha: 1)
            badge.backgroundColor = UIColor.white.withAlphaComponent(0.9)
            badge.layer.cornerRadius = 12
            badge.layer.masksToBounds = true
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
            badgeRow.addArrangedSubview(badge)
        }

        addSubview(badgeRow)
        NSLayoutConstraint.activate([
            badgeRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            badgeRow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            badgeRow.heightAnchor.constraint(equalToConstant: 24),
        ])

        graphLayer.strokeColor = UIColor.white.withAlphaComponent(0.95).cgColor
        graphLayer.fillColor = UIColor.clear.cgColor
        graphLayer.lineWidth = 4
        graphLayer.lineCap = .round
        layer.addSublayer(graphLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let path = UIBezierPath()
        let baseline = bounds.height - 42
        path.move(to: CGPoint(x: 22, y: baseline))
        path.addCurve(
            to: CGPoint(x: bounds.width - 24, y: baseline - 16),
            controlPoint1: CGPoint(x: bounds.width * 0.28, y: baseline - 56),
            controlPoint2: CGPoint(x: bounds.width * 0.58, y: baseline + 18)
        )
        graphLayer.frame = bounds
        graphLayer.path = path.cgPath
    }
}

private final class LayerMaskSampleView: BaseSampleView {

    private let maskedPanel = UIView()
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "Mask"
        subtitleLabel.text = "用 CAShapeLayer 当 mask，只有星形区域能看到下面的渐变。"

        backgroundColor = UIColor(red: 0.13, green: 0.15, blue: 0.20, alpha: 1)
        layer.cornerRadius = 28

        maskedPanel.translatesAutoresizingMaskIntoConstraints = false
        maskedPanel.backgroundColor = UIColor(red: 0.11, green: 0.12, blue: 0.18, alpha: 1)
        maskedPanel.layer.cornerRadius = 20

        gradientLayer.colors = [
            UIColor(red: 0.16, green: 0.82, blue: 0.76, alpha: 1).cgColor,
            UIColor(red: 0.24, green: 0.53, blue: 0.99, alpha: 1).cgColor,
            UIColor(red: 0.98, green: 0.44, blue: 0.55, alpha: 1).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        addSubview(maskedPanel)
        maskedPanel.layer.addSublayer(gradientLayer)

        NSLayoutConstraint.activate([
            maskedPanel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            maskedPanel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            maskedPanel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            maskedPanel.heightAnchor.constraint(equalToConstant: 82),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = maskedPanel.bounds

        let center = CGPoint(x: maskedPanel.bounds.midX, y: maskedPanel.bounds.midY)
        let points = 5
        let outerRadius: CGFloat = 42
        let innerRadius: CGFloat = 18
        let path = UIBezierPath()

        for index in 0..<(points * 2) {
            let angle = (CGFloat(index) * .pi / CGFloat(points)) - .pi / 2
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.black.cgColor
        maskedPanel.layer.mask = maskLayer
    }
}
