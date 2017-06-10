

import Foundation

@IBDesignable class BorderButton: UIButton {
    
    var cornerRadius: CGFloat {
        return frame.height/9
    }
    
    @IBInspectable var borderWidth: CGFloat = 1 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
            setTitleColor(borderColor, for: .normal)
        }
    }
    override var isHighlighted: Bool {
        didSet {
            invalidateAppearance()
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        invalidateAppearance()
    }
    
    override var intrinsicContentSize: CGSize {
        guard let label = titleLabel else { return super.intrinsicContentSize }
        
        let size = label.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        
        let height = size.height + 10
        let width  = size.width + 15
        
        return CGSize(width: width, height: height)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        borderWidth = 1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius  = cornerRadius
        layer.masksToBounds = cornerRadius > 0
    }
    
    func invalidateAppearance() {
        let isDimmed = tintAdjustmentMode == .dimmed
        let filled = isDimmed ? false : isHighlighted
        let color: UIColor = isDimmed ? tintColor : isHighlighted ? borderColor ?? tintColor : tintColor
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.allowUserInteraction, .curveEaseInOut], animations: { [unowned self] in
            self.layer.borderColor = color.cgColor
            if filled {
                self.backgroundColor = color
                self.setTitleColor(.white, for: .highlighted)
            } else {
                self.backgroundColor = .clear
                self.setTitleColor(color, for: .normal)
            }
        })
    }
}
