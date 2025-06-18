//
//  LogisticCurveView.swift
//  test-ui
//
//  Created by v-huchu on 2025/6/18.
//

import UIKit

class LogisticCurveView: UIView {
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setStrokeColor(UIColor.systemBlue.cgColor)
        ctx.setLineWidth(2)

        var isFirst = true
        for x in stride(from: -6.0, through: 6.0, by: 0.1) {
            let y = 1.0 / (1.0 + exp(-x))
            let px = CGFloat((x + 6) / 12.0) * rect.width
            let py = CGFloat((1.0 - y)) * rect.height  // Y反转（上0下1）
            if isFirst {
                ctx.move(to: CGPoint(x: px, y: py))
                isFirst = false
            } else {
                ctx.addLine(to: CGPoint(x: px, y: py))
            }
        }

        ctx.strokePath()
    }
}
