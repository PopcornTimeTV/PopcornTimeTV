

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
    
    var bufferColor: UIColor = .darkGray {
        didSet {
            fillLayer.fillColor = bufferColor.cgColor
        }
    }
    var borderColor: UIColor = .darkGray {
        didSet {
            borderLayer.borderColor = borderColor.cgColor
        }
    }
    var elapsedColor: UIColor = .darkGray {
        didSet {
            coverLayer.fillColor = elapsedColor.cgColor
        }
    }
    
    private let borderLayer = CAShapeLayer()
    private let borderMaskLayer = CAShapeLayer()
    private let fillLayer = CAShapeLayer()
    private let fillMaskLayer = CAShapeLayer()
    private let coverMaskLayer = CAShapeLayer()
    private let coverLayer = CAShapeLayer()
    
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
        
        fillLayer.fillColor = bufferColor.cgColor
        fillLayer.mask = fillMaskLayer
        
        coverLayer.mask = coverMaskLayer
        coverLayer.fillColor = elapsedColor.cgColor
        
        layer.addSublayer(borderLayer)
        layer.addSublayer(fillLayer)
        layer.addSublayer(coverLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let inset = borderLayer.lineWidth/2.0
        let borderRect = bounds.insetBy(dx: inset, dy: inset)
        let radius = bounds.size.height/2.0
        let path = UIBezierPath(roundedRect: borderRect, cornerRadius: radius)
        
        borderLayer.path      = path.cgPath
        borderMaskLayer.path  = path.cgPath
        borderMaskLayer.frame = bounds
        
        let bufferRect = CGRect(origin: .zero, size: CGSize(width: bounds.width * CGFloat(bufferProgress), height: bounds.height))
        let bufferPath = UIBezierPath(rect: bufferRect)
        
        fillLayer.path      = bufferPath.cgPath
        fillMaskLayer.path  = path.cgPath
        borderLayer.frame   = bounds
        fillLayer.frame     = bounds
        fillMaskLayer.frame = bounds
        
        let playerRect = CGRect(origin: .zero, size: CGSize(width: bounds.width * CGFloat(elapsedProgress), height: bounds.height))
        let playerPath = UIBezierPath(rect: playerRect)
        
        coverLayer.path      = playerPath.cgPath
        coverMaskLayer.path  = path.cgPath
        coverLayer.frame     = bounds
        coverMaskLayer.frame = bounds
    }
}
