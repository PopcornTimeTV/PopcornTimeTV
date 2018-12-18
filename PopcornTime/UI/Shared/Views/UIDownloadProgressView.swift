

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
    
    @IBInspectable var isFilled: Bool = false {
        didSet {
            guard oldValue != isFilled else { return }
            setNeedsDisplay()
        }
    }
    
    override var frame: CGRect {
        didSet {
            guard oldValue != frame else { return }
            setNeedsDisplay()
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let center = CGPoint(x: rect.size.width/2, y: rect.size.height/2)
        
        let path = UIBezierPath()
        tintColor.setStroke()
        tintColor.setFill()
        
        let lineWidth = isFilled ? 0 : self.lineWidth
        
        path.addArc(withCenter: center,
                    radius: Swift.min(center.x, center.y) - (lineWidth/2),
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true)
        path.lineWidth = lineWidth
        
        if isFilled {
            path.addLine(to: center)
            path.close()
        }
        
        isFilled ? path.fill() : path.stroke()
    }
    
    func sharedSetup() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    init(startAngle: CGFloat = .pi * 1.5, endAngle: CGFloat = (.pi * 1.5) + (.pi * 2), lineWidth: CGFloat = 1, frame: CGRect = .zero, isFilled: Bool = false) {
        super.init(frame: frame)
        
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.lineWidth = lineWidth
        self.isFilled = isFilled
        
        sharedSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedSetup()
    }
}
