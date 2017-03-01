

import Foundation

@IBDesignable class MonogramCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var initialsLabel: UILabel!
    
    
    var originalImage: UIImage? {
        didSet {
            if let image = originalImage?.rounded(with: imageView.bounds.size) {
                imageView.image = image
                initialsLabel.isHidden = true
            } else {
                // TODO: Set placeholder nondynamic blurred image.
                imageView.image = nil
                initialsLabel.isHidden = false
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if imageView.image?.size != imageView.bounds.size {
            originalImage = (originalImage) // Refresh image only when bounds change.
        }
        
        if let highlightView = highlightView {
            highlightView.layer.cornerRadius = imageView.bounds.size.width/2.0
            highlightView.layer.masksToBounds = true
        }
        
    }
    
    #if os(tvOS)
    
    @IBInspectable var subtitleLabelUnfocusedColor = UIColor(white: 1.0, alpha: 0.3)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        subtitleLabel.textColor = subtitleLabelUnfocusedColor
        subtitleLabel.layer.zPosition = 10
        subtitleLabel.layer.shadowColor = UIColor.black.cgColor
        subtitleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        subtitleLabel.layer.shadowRadius = 2
        subtitleLabel.layer.shadowOpacity = 0.6
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        subtitleLabel.textColor = isFocused ? titleLabelFocusedColor : subtitleLabelUnfocusedColor
    }
    
    #endif
}
