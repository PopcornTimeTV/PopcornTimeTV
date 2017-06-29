

import Foundation

@IBDesignable class UIDownloadProgressView: UIView {
    
    @IBInspectable var startAngle: CGFloat = .pi * 1.5 {
        didSet {
            guard oldValue != startAngle else { return }
            setNeedsDisplay()
        }
    }
    @IBInspectable var endAngle: CGFloat = (.pi * 1.5) + (.pi * 2) {
        didSet {
            guard oldValue != endAngle else { return }
            setNeedsDisplay()
        }
    }
    @IBInspectable var lineWidth: CGFloat = 1 {
        didSet {
            guard oldValue != lineWidth else { return }
            setNeedsDisplay()
        }
    }
    
    override var frame: CGRect {
        didSet {
            guard oldValue != frame else { return }
            setNeedsDisplay()
        }
    }
    
    var isFilled: Bool = false {
        didSet {
            guard oldValue != isFilled else { return }
            setNeedsDisplay()
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        tintColor.setStroke()
        isFilled ? tintColor.setFill() : UIColor.clear.setFill()
        
        path.addArc(withCenter: CGPoint(x: rect.size.width/2, y: rect.size.height/2),
                    radius: Swift.min(rect.size.width/2, rect.size.height/2) - (lineWidth/2),
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true)
        path.lineWidth = lineWidth
        
        path.stroke()
        path.fill()
    }
    
    func sharedSetup() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
        #if os(iOS)
        isExclusiveTouch = false
        #endif
    }
    
    init(startAngle: CGFloat = .pi * 1.5, endAngle: CGFloat = (.pi * 1.5) + (.pi * 2), lineWidth: CGFloat = 1, frame: CGRect = .zero) {
        super.init(frame: frame)
        
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.lineWidth = lineWidth
        
        sharedSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedSetup()
    }
}
