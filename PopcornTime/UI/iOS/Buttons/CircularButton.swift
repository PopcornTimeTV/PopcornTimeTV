

import UIKit

@IBDesignable class CircularButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            backgroundView.layer.cornerRadius = cornerRadius
            backgroundView.layer.masksToBounds = cornerRadius > 0
        }
    }
    
    var imageTransform: CGAffineTransform = CGAffineTransform(scaleX: 0.5, y: 0.5) {
        didSet {
            updatedImageView.transform = imageTransform
        }
    }
    
    let backgroundView = UIView()
    private var updatedImageView = UIImageView()
    
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
        insertSubview(backgroundView, at: 0)
        
        guard let imageView = imageView else { return }
        
        updatedImageView = UIImageView(image: imageView.image?.withRenderingMode(.alwaysTemplate))
        updatedImageView.frame = imageView.bounds
        updatedImageView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        updatedImageView.isUserInteractionEnabled = false
        imageView.removeFromSuperview()
        addSubview(updatedImageView)
        updatedImageView.transform = imageTransform
        cornerRadius = frame.width/2
        
        backgroundView.backgroundColor = tintColor
        updatedImageView.tintColor = .dark
    }
    
    override var tintColor: UIColor! {
        didSet {
            backgroundView.backgroundColor = tintColor
            updatedImageView.tintColor = .dark
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: [.allowUserInteraction, .curveEaseInOut], animations: { [unowned self] in
                self.alpha = self.isHighlighted ? 0.3 : 1.0
            })
        }
    }
}
