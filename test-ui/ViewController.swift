import UIKit
import SnapKit



class ViewController: UIViewController {
    private static var _images:BubbleContainer.BubbleImageSlices? = BubbleContainer.BubbleImageSlices.sliceBubbleImage("ad_sports_group_map_bubble_group")

    static var imagess :BubbleContainer.BubbleImageSlices  {
        if(_images==nil){
            _images = BubbleContainer.BubbleImageSlices.sliceBubbleImage("ad_sports_group_map_bubble_group")
        }
        return _images!
    }
    static let imagessJoined = { BubbleContainer.BubbleImageSlices.sliceBubbleImage("ad_sports_group_map_bubble_group_joined")}()
    //private var imageView: UIImageView!
    private var widthButton: UIButton!
    private var heightButton: UIButton!
    var imageView: BubbleContainer!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // 创建 imageView
        //        let rawImage = UIImage(named: "ad_sports_group_map_bubble_group")
        //        let stretchableImage = rawImage?.resizableImage(
        //            withCapInsets: UIEdgeInsets(top: 24, left: 0, bottom: 42, right: 0),//上下不变形
        //            //withCapInsets: UIEdgeInsets(top: 24, left: 30, bottom: 42, right: 0),//左边不变形，上下不变形
        //            resizingMode: .stretch
        //        )
        //        imageView = UIImageView(image: stretchableImage)
        //        imageView.isUserInteractionEnabled = true
        //        imageView.contentMode = .scaleToFill
        //        imageView.backgroundColor = UIColor.red
        //        imageView.frame = CGRect(x: 100, y: 200, width: 99, height: 70)
        
        //imageView =  BubbleContainer(imageBaseName: "ad_sports_group_map_bubble_group_joined")
        let imagess = BubbleContainer.BubbleImageSlices.sliceBubbleImage("ad_sports_group_map_bubble_group")
        imageView =  BubbleContainer(imagess:imagess)
        //imageView = BubbleContainer("ad_sports_group_map_bubble_group_joined")
        
        
        //imageView.imagess = BubbleContainer.BubbleImageSlices.sliceBubbleImage("ad_sports_group_map_bubble_group_joined")
        imageView.frame = CGRect(x: 100, y: 200, width: 200, height: 70)
//        imageView.backgroundColor = UIColor.red
        view.addSubview( imageView)
        //view.addSubview(imageView)
        
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
        if newFrame.size.width < 45 { newFrame.size.width = 45 }
        
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
        
        
        //imageview.image = []
        gesture.setTranslation(.zero, in: view)
    }
}

/// 你在代码里写的 withCapInsets(top: 24, left: 30, bottom: 42, right: 0) 是点 (pt)。
//iOS 会根据图片的 scale（比如 2x图就是 60px 左边）自动换算成正确的像素数。
//不用自己管缩放，直接用点值传进去就对了！
//
//If the sum of the top and bottom values in the cap insets is greater than the height of the image (or the sum of the left and right is greater than the width), the middle area is treated as having zero or negative size, which can lead to unpredictable rendering results.
//
//——（翻译：Insets 总和大于图片尺寸时，中间区域被认为是 0 或负数大小，可能会出现不可预测的渲染效果）
class BubbleContainer: UIView {
    private let leftImgView = UIImageView()
    private let centerImgView = UIImageView()
    private let rightImgView = UIImageView()
    private var leftCap:CGFloat = 27
    private var rightCap:CGFloat = 27
    
    var imagess: BubbleImageSlices? {
        didSet {
            loadImages()
        }
    }
    
    var centerWidth: CGFloat = 45 {
        didSet {
            centerImgView.snp.updateConstraints { make in
                make.width.equalTo(centerWidth)
            }
        }
    }
    
    var imageBaseName: String = "ad_sports_group_map_bubble_group"  {
        didSet {
            imagess = BubbleImageSlices.sliceBubbleImage(imageBaseName, rLeftCap: leftCap, rRightCap: rightCap)
            loadImages()
        }
    }
    
    init(imageBaseName: String = "ad_sports_group_map_bubble_group",
         centerWidth: CGFloat = 45,
         leftCap: CGFloat = 27,
         rightCap: CGFloat = 27) {
        
        self.imageBaseName = imageBaseName
        self.centerWidth = centerWidth
        self.leftCap = leftCap
        self.rightCap = rightCap
        super.init(frame: .zero)
        
        setupViews()
        imagess = BubbleImageSlices.sliceBubbleImage(imageBaseName, rLeftCap: leftCap, rRightCap: rightCap)
        loadImages()
    }
    
    init(imagess: BubbleImageSlices?, centerWidth: CGFloat = 45) {
        self.imagess = imagess
        super.init(frame: .zero)
        setupViews()
        loadImages()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        isUserInteractionEnabled = false
        
        [leftImgView, centerImgView, rightImgView].forEach {
            $0.contentMode = .scaleToFill
            addSubview($0)
        }
        
        leftImgView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        
        centerImgView.snp.makeConstraints { make in
            make.leading.equalTo(leftImgView.snp.trailing)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(centerWidth)
        }
        
        rightImgView.snp.makeConstraints { make in
            make.leading.equalTo(centerImgView.snp.trailing)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(leftImgView.snp.width)
            make.trailing.equalToSuperview()
        }
    }
    
    private func loadImages() {
        let left = imagess?.left.resizableImage(
            withCapInsets: UIEdgeInsets(top: 25, left: 30, bottom: 44, right: 0),
            resizingMode: .stretch)
        
        let center = imagess?.center.resizableImage(
            withCapInsets: UIEdgeInsets(top: 25, left: 30, bottom: 44, right: 0),
            resizingMode: .stretch)
        
        let right = imagess?.right.resizableImage(
            withCapInsets: UIEdgeInsets(top: 25, left: 0, bottom: 44, right: 30),
            resizingMode: .stretch)
        
        leftImgView.image = left
        centerImgView.image = center
        rightImgView.image = right
    }
    
    struct BubbleImageSlices {
        let left: UIImage
        let center: UIImage
        let right: UIImage
        
        static func sliceBubbleImage(_ imageName: String, rLeftCap: CGFloat = 27, rRightCap: CGFloat = 27) -> BubbleImageSlices? {
            let image = UIImage.init(named: imageName) ?? UIImage.init()
            guard let cgImage = image.cgImage else { return nil }
            let width = CGFloat(cgImage.width)
            let height = CGFloat(cgImage.height)

            let scale = image.scale
            let orientation = image.imageOrientation
            
            let leftCap = rLeftCap * scale
            let rightCap = rRightCap * scale
            guard leftCap + rightCap < width else { return nil }

            // 切出左图
            let leftRect = CGRect(x: 0, y: 0, width: leftCap, height: height)
            guard let leftCg = cgImage.cropping(to: leftRect) else { return nil }
            let leftImage = UIImage(cgImage: leftCg, scale: scale, orientation: orientation)
            
            // 中间
            let centerRect = CGRect(x: leftCap, y: 0, width: width - leftCap - rightCap, height: height)
            guard let centerCg = cgImage.cropping(to: centerRect) else { return nil }
            let centerImage = UIImage(cgImage: centerCg, scale: scale, orientation: orientation)
            
            // 右图
            let rightRect = CGRect(x: width - rightCap, y: 0, width: rightCap, height: height)
            guard let rightCg = cgImage.cropping(to: rightRect) else { return nil }
            let rightImage = UIImage(cgImage: rightCg, scale: scale, orientation: orientation)
            
            return BubbleImageSlices(left: leftImage, center: centerImage, right: rightImage)
        }
    }
}

