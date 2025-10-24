//
//  ViewController.swift
//  test-image-stretch
//
//  Created by huchu on 2025/10/24.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // 原始图片
        guard let originalImage = UIImage(named: "runningRoute_mark_icon_selected") else {
            print("❌ 图片未找到，请检查资源名")
            return
        }
        
        //        // 执行拉伸逻辑并展示中间过程
                showStretchSteps(with: originalImage)
        
 
//        let image = originalImage.stretchableImage(withLeftCapWidth: Int(originalImage.size.width * 0.3), topCapHeight: 0);
//        
//        let imageView = UIImageView(frame: CGRect(x: 0, y: 120, width: 200, height: 53))
//        imageView.image = image
//        
//        view.addSubview(imageView)
//        
//        let image2 = image.stretchableImage(withLeftCapWidth: Int(originalImage.size.width * 0.6), topCapHeight: 0)
//        let imageView2 = UIImageView(frame: CGRect(x: 0, y: 180, width: 200, height: 53))
//        imageView2.image = image2
//        view.addSubview(imageView2)
    }
    
    
    /// 展示每一步的拉伸效果
    private func showStretchSteps(with image: UIImage) {
        let targetSize = CGSize(width: 300, height: 53)
        
        // 原图展示
        let imageView1 = createImageView(y: 100, image: image, label: "原始图片", width: image.size.width);
        
        // 第一次拉伸右边（保护左边）
        let newImg = image.stretchableImage(withLeftCapWidth: Int(image.size.width * 0.3), topCapHeight: 0)
        let tempWidth = targetSize.width / 2 + image.size.width / 2
        UIGraphicsBeginImageContextWithOptions(CGSize(width: tempWidth, height: image.size.height), false, image.scale)
        newImg.draw(in: CGRect(x: 0, y: 0, width: tempWidth, height: targetSize.height))
        let firstStretch = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let imageView2 = createImageView(y: 200, image: firstStretch, label: "第一次拉伸（右边拉伸）",width: tempWidth)
        
        // 第二次拉伸左边（保护右边）
        let margin = firstStretch?.size.width ?? 0
        let secondStrechImage = firstStretch?.stretchableImage(withLeftCapWidth: Int(tempWidth - image.size.width * 0.3), topCapHeight: 0)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: targetSize.width, height: image.size.height), false, image.scale)
        secondStrechImage?.draw(in: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
        let finalResult = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let imageView3 = createImageView(y: 300, image: secondStrechImage, label: "第二次拉伸准备图",width: targetSize.width)
        let imageView4 = createImageView(y: 400, image: finalResult, label: "最终结果",width: targetSize.width)
        
        // 添加到视图
        [imageView1, imageView2, imageView3, imageView4].forEach { view.addSubview($0) }
    }
    
    
    /// 工具方法：创建带标题的 ImageView
    private func createImageView(y: CGFloat, image: UIImage?, label: String,width:Double) -> UIView {
        let container = UIView(frame: CGRect(x: 20, y: y, width: width, height: 80))
        
        let title = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: 20))
        title.text = label
        title.font = .systemFont(ofSize: 13)
        title.textColor = .darkGray
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 25, width: width, height: 53))
        imageView.contentMode = .scaleToFill
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.image = image
        
        container.addSubview(title)
        container.addSubview(imageView)
        return container
    }
    
    
    private func doubleStretchLeftAndRightWithContainerSize(size: CGSize, oraimage: UIImage?) -> UIImage? {
        guard let image = oraimage else { return nil }
        
        guard size.width > 0, size.height > 0 else { return nil }
        guard size.width < 400, size.height < 400 else { return nil }
        guard image.size.width > 0, image.scale > 0 else { return nil }
        
        let imageSize = image.size
        let newImg = image.stretchableImage(withLeftCapWidth: Int(27), topCapHeight: 0)
        let tempWidth = size.width / 2 + imageSize.width / 2
        guard tempWidth > 0 else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: tempWidth, height: size.height), false, image.scale)
        newImg.draw(in: CGRect(x: 0, y: 0, width: tempWidth, height: size.height))
        let firstStretch = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let stretched = firstStretch else { return nil }
        guard stretched.size.width > 27 else { return nil }
        let secondStretched = stretched.stretchableImage(withLeftCapWidth: Int(stretched.size.width-27), topCapHeight: 0)
        
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        secondStretched.draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
    
    
    /// 上下双向拉伸图片（Top–Bottom Stretch）
    ///
    /// 通过两次纵向拉伸，让图片的上下两端都被平滑延展，
    /// 常用于背景条、按钮、气泡、渐变条等上下可拉伸场景。
    ///
    /// - Parameters:
    ///   - size: 目标尺寸（主要用 height）
    ///   - oraimage: 原始图片
    /// - Returns: 拉伸后的图片
    private func doubleStretchTopAndBottomWithContainerSize(size: CGSize, oraimage: UIImage?) -> UIImage? {
        guard let image = oraimage else { return nil }
        
        let imageSize = image.size
        let targetSize = size
        
        // ===================== 第一次：拉伸下边，保护上边 =====================
        // withTopCapHeight: 上方保护区高度；从该点开始往下可拉伸
        // 这里保护上方 30%，拉伸下方 70%
        let newImg = image.stretchableImage(
            withLeftCapWidth: 0, // 不做横向拉伸
            topCapHeight: Int(imageSize.height * 0.3)
        )
        
        // 第一次拉伸的过渡高度（中间态）
        // 类似于横向版本： (原高度 + 目标高度) / 2
        let tempHeight = targetSize.height / 2 + imageSize.height / 2
        
        // 绘制第一次拉伸后的中间图
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageSize.width, height: tempHeight), false, image.scale)
        newImg.draw(in: CGRect(x: 0, y: 0, width: targetSize.width, height: tempHeight))
        let firstStretchImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // ===================== 第二次：拉伸上边，保护下边 =====================
        let margin = firstStretchImage?.size.height ?? 0
        // 保护上方 80%，拉伸下方 20%（微调）
        let secondStretchImage = firstStretchImage?.stretchableImage(
            withLeftCapWidth: 0,
            topCapHeight: Int(margin * 0.8)
        )
        
        // 绘制最终目标高度的图像
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageSize.width, height: targetSize.height), false, image.scale)
        secondStretchImage?.draw(in: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
        let resultImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultImg
    }

}
