

import Foundation

@IBDesignable class BlurButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            backgroundView.layer.cornerRadius = cornerRadius
            backgroundView.layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var blurTint: UIColor = .clear {
        didSet {
            backgroundView.contentView.backgroundColor = blurTint
        }
    }
    var blurStyle: UIBlurEffectStyle = .light {
        didSet {
            backgroundView.effect = UIBlurEffect(style: blurStyle)
        }
    }
    
    var imageTransform: CGAffineTransform = CGAffineTransform(scaleX: 0.5, y: 0.5) {
        didSet {
            updatedImageView.transform = imageTransform
        }
    }
    
    var backgroundView: UIVisualEffectView
    fileprivate var updatedImageView = UIImageView()
    
    override init(frame: CGRect) {
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        super.init(frame: frame)
        setUpButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        super.init(coder: aDecoder)
        setUpButton()
    }
    
    func setUpButton() {
        backgroundView.frame = bounds
        backgroundView.isUserInteractionEnabled = false
        insertSubview(backgroundView, at: 0)
        
        guard let imageView = imageView else { return }
        
        updatedImageView = UIImageView(image: imageView.image)
        updatedImageView.frame = imageView.bounds
        updatedImageView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        updatedImageView.isUserInteractionEnabled = false
        imageView.removeFromSuperview()
        addSubview(updatedImageView)
        updatedImageView.transform = imageTransform
        cornerRadius = frame.width/2
    }
    
    override var isHighlighted: Bool {
        didSet {
            updateColor(isHighlighted)
        }
    }
    
    func updateColor(_ tint: Bool) {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.allowUserInteraction, .curveEaseInOut], animations: { [unowned self] in
            self.backgroundView.contentView.backgroundColor = tint ? .white : self.blurTint
        })
    }
}
