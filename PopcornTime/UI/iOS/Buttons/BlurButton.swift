

import Foundation

class BlurButton: UIButton {
    
    let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundView.frame = bounds
        backgroundView.layer.cornerRadius = frame.width/2
        backgroundView.layer.masksToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpButton()
    }
    
    func setUpButton() {
        backgroundView.frame = bounds
        backgroundView.isUserInteractionEnabled = false
        
        addSubview(backgroundView)
        backgroundColor = .clear
        
        if let imageView = imageView {
            let updatedImageView = UIImageView(image: imageView.image)
            updatedImageView.frame = imageView.bounds
            updatedImageView.center = CGPoint(x: bounds.midX, y: bounds.midY)
            updatedImageView.isUserInteractionEnabled = false
            imageView.removeFromSuperview()
            addSubview(updatedImageView)
            updatedImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
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
        let color: UIColor = isDimmed ? tintColor : isHighlighted ? .white : .clear
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.allowUserInteraction, .curveEaseInOut], animations: { [unowned self] in
            self.backgroundView.contentView.backgroundColor = color
        })
    }
}
