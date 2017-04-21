

import Foundation

@IBDesignable class BorderButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var borderWidth: CGFloat = 0 {
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
            updateColor(isHighlighted, borderColor)
        }
    }
    
    override func tintColorDidChange() {
        if tintAdjustmentMode == .dimmed {
            updateColor(false)
        } else {
            updateColor(false, borderColor)
        }
    }
    
    func updateColor(_ highlighted: Bool, _ color: UIColor? = nil) {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.allowUserInteraction, .curveEaseInOut], animations: { [unowned self] in
            if highlighted {
                self.backgroundColor =  color ?? self.tintColor
                self.layer.borderColor = color?.cgColor ?? self.tintColor?.cgColor
                self.setTitleColor(.white, for: .highlighted)
            } else {
                self.backgroundColor = .clear
                self.layer.borderColor = color?.cgColor ?? self.tintColor?.cgColor
                self.setTitleColor(color ?? self.tintColor, for: .normal)
            }
        })
    }
}
