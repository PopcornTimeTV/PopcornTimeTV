

import UIKit

class CircularButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width/2
        layer.masksToBounds = true
    }
    
    private var classContext = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView?.isHidden = true
        imageView?.addObserver(self, forKeyPath: "image", options: .new, context: &classContext)
        observeValue(forKeyPath: "image", of: imageView, change: nil, context: &classContext)
        backgroundColor = tintColor
    }
    
    override var intrinsicContentSize: CGSize {
        guard let imageView = imageView else { return super.intrinsicContentSize }
        
        let size = imageView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        let common = Swift.max(size.width, size.height)
        let padding: CGFloat = 10
        
        return CGSize(width: common + padding, height: common + padding)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, keyPath == "image", context == &classContext {
            if let layer = imageView?.image?.scaled(to: intrinsicContentSize).layerMask {
                layer.frame = bounds
                self.layer.mask = layer
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        invalidateAppearance()
    }
    
    override var isHighlighted: Bool {
        didSet {
            invalidateAppearance()
        }
    }
    
    func invalidateAppearance() {
        let isDimmed = tintAdjustmentMode == .dimmed
        let color: UIColor = isDimmed ? tintColor : isHighlighted ? tintColor.withAlphaComponent(0.3) : tintColor
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.allowUserInteraction, .curveEaseInOut], animations: { [unowned self] in
            self.backgroundColor = color
        })
    }
    
    deinit {
        do { try imageView?.remove(self, for: "image", in: &classContext) } catch {}
    }
}
