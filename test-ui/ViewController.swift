import UIKit

class ViewController: UIViewController {
    private var imageView: UIImageView!
    private var widthButton: UIButton!
    private var heightButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // 创建 imageView
        let rawImage = UIImage(named: "ad_sports_group_map_bubble_group")
        let stretchableImage = rawImage?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30),
            resizingMode: .stretch
        )
        imageView = UIImageView(image: stretchableImage)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleToFill
        imageView.backgroundColor = UIColor.red
        imageView.frame = CGRect(x: 100, y: 200, width: 99, height: 70)
        view.addSubview(imageView)

        // 添加调节宽度按钮
        widthButton = UIButton(type: .custom)
        widthButton.frame = CGRect(x: imageView.frame.maxX - 30, y: imageView.frame.maxY - 30, width: 30, height: 30)
        widthButton.backgroundColor = .blue
        widthButton.setTitle("⇔", for: .normal)
        widthButton.addTarget(self, action: #selector(startWidthResize), for: .touchDown)
        view.addSubview(widthButton)

        // 添加调节高度按钮
        heightButton = UIButton(type: .custom)
        heightButton.frame = CGRect(x: imageView.frame.minX - 30, y: imageView.frame.maxY - 30, width: 30, height: 30)
        heightButton.backgroundColor = .green
        heightButton.setTitle("⇕", for: .normal)
        heightButton.addTarget(self, action: #selector(startHeightResize), for: .touchDown)
        view.addSubview(heightButton)
    }

    @objc func startWidthResize() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleWidthResize(_:)))
        widthButton.addGestureRecognizer(panGesture)
    }

    @objc func handleWidthResize(_ gesture: UIPanGestureRecognizer) {
        guard let button = gesture.view else { return }
        let translation = gesture.translation(in: view)

        var newFrame = imageView.frame
        newFrame.size.width += translation.x
        if newFrame.size.width < 50 { newFrame.size.width = 50 }

        imageView.frame = CGRect(x: imageView.frame.origin.x, y: imageView.frame.origin.y, width: newFrame.size.width, height: imageView.frame.size.height)

        // 更新按钮位置
        widthButton.frame.origin = CGPoint(x: imageView.frame.maxX - 30, y: imageView.frame.maxY - 30)
        heightButton.frame.origin = CGPoint(x: imageView.frame.minX - 30, y: imageView.frame.maxY - 30)

        gesture.setTranslation(.zero, in: view)
    }

    @objc func startHeightResize() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleHeightResize(_:)))
        heightButton.addGestureRecognizer(panGesture)
    }

    @objc func handleHeightResize(_ gesture: UIPanGestureRecognizer) {
        guard let button = gesture.view else { return }
        let translation = gesture.translation(in: view)

        var newFrame = imageView.frame
        newFrame.size.height += translation.y
        if newFrame.size.height < 30 { newFrame.size.height = 30 }

        imageView.frame = CGRect(x: imageView.frame.origin.x, y: imageView.frame.origin.y, width: imageView.frame.size.width, height: newFrame.size.height)

        // 更新按钮位置
        widthButton.frame.origin = CGPoint(x: imageView.frame.maxX - 30, y: imageView.frame.maxY - 30)
        heightButton.frame.origin = CGPoint(x: imageView.frame.minX - 30, y: imageView.frame.maxY - 30)

        gesture.setTranslation(.zero, in: view)
    }
}
