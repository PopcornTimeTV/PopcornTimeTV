

import Foundation

class BufferingBar: UIView {
    var bufferProgress: Float = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }
    var elapsedProgress: Float = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    var bufferColor: UIColor = .clear {
        didSet {
            bufferView.contentView.tintColor = bufferColor
        }
    }
    var borderColor: UIColor = UIColor(white: 1.0, alpha: 0.5) {
        didSet {
            borderLayer.borderColor = borderColor.cgColor
        }
    }
    var elapsedColor: UIColor = .clear {
        didSet {
            elapsedView.contentView.tintColor = elapsedColor
        }
    }
    
    private let borderLayer = CAShapeLayer()
    private let borderMaskLayer = CAShapeLayer()
    
    private let elapsedView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let elapsedMaskLayer = CAShapeLayer()
    
    private let bufferView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let bufferMaskLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedSetup()
    }
    
    func sharedSetup() {
        borderLayer.borderWidth = 1.0
        borderLayer.borderColor = borderColor.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.mask = borderMaskLayer
        
        bufferView.layer.mask = bufferMaskLayer
        bufferView.contentView.tintColor = bufferColor
        
        elapsedView.layer.mask = elapsedMaskLayer
        elapsedView.contentView.tintColor = elapsedColor
        
        layer.addSublayer(borderLayer)
        addSubview(elapsedView)
        addSubview(bufferView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let inset = borderLayer.lineWidth/2.0
        let borderRect = bounds.insetBy(dx: inset, dy: inset)
        let radius = bounds.size.height/2.0
        let path = UIBezierPath(roundedRect: borderRect, cornerRadius: radius)
        
        borderLayer.path        = path.cgPath
        borderMaskLayer.path    = path.cgPath
        borderMaskLayer.frame   = bounds
        borderLayer.frame       = bounds
        
        let playerRect = CGRect(origin: .zero, size: CGSize(width: bounds.width * CGFloat(elapsedProgress), height: bounds.height))
        
        elapsedMaskLayer.path   = path.cgPath
        elapsedMaskLayer.frame  = bounds
        elapsedView.frame       = playerRect
        
        let bufferRect = CGRect(origin: CGPoint(x: playerRect.maxX, y: 0), size: CGSize(width: (bounds.width - playerRect.width) * CGFloat(bufferProgress), height: bounds.height))
        
        bufferMaskLayer.path    = path.cgPath
        bufferMaskLayer.frame   = bounds
        bufferView.frame        = bufferRect
    }
}
