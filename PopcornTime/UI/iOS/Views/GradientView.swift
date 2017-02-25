

import Foundation

@IBDesignable class GradientView: UIView {
    
    @IBInspectable var isHorizontal: Bool = false {
        didSet {
            guard isHorizontal != oldValue else { return }
            
            isVertical = !isHorizontal
            configureView()
        }
    }
    
    @IBInspectable var isVertical: Bool = true {
        didSet {
            guard isVertical != oldValue else { return }
            
            isHorizontal = !isVertical
            configureView()
        }
    }

    @IBInspectable var topColor: UIColor = .clear {
        didSet {
            configureView()
        }
    }
    @IBInspectable var bottomColor: UIColor = .black {
        didSet {
            configureView()
        }
    }
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    func configureView() {
        let layer = self.layer as! CAGradientLayer
        
        layer.startPoint = isHorizontal ? CGPoint(x: 0.0, y: 0.5) : CGPoint(x: 0.5, y: 0.0)
        layer.endPoint   = isHorizontal ? CGPoint(x: 1.0, y: 0.5) : CGPoint(x: 0.5, y: 1.0)
        
        layer.colors = [topColor.cgColor, bottomColor.cgColor]
    }
    
}
