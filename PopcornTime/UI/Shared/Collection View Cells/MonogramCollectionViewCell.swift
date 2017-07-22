

import Foundation

@IBDesignable class MonogramCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var initialsLabel: UILabel!
    
    
    var originalImage: UIImage? {
        didSet {
            if let image = originalImage?.rounded(to: imageView.bounds.size) {
                imageView.image = image
                initialsLabel.isHidden = true
            } else {
                imageView.image = UIImage(named:"Static Light Blur")?.rounded(to: imageView.bounds.size)
                initialsLabel.isHidden = false
            }
        }
    }
    
    override var isDark: Bool {
        didSet {
            guard oldValue != isDark else { return }
            
            titleLabel.textColor = isFocused ? .white : colorPallete.primary
            subtitleLabel.textColor = isFocused ? .white : colorPallete.tertiary
            
            titleLabel.layer.shadowColor = isDark || isFocused ? UIColor.black.cgColor : UIColor.clear.cgColor
            subtitleLabel.layer.shadowColor = isDark || isFocused ? UIColor.black.cgColor : UIColor.clear.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if imageView.image?.size != imageView.bounds.size {
            originalImage = { originalImage }() // Refresh image only when bounds change.
        }
        
        if let highlightView = highlightView {
            highlightView.layer.cornerRadius = imageView.bounds.size.width/2.0
            highlightView.layer.masksToBounds = true
        }
        
    }
    
    #if os(tvOS)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        subtitleLabel.textColor = colorPallete.tertiary
        subtitleLabel.layer.zPosition = 10
        subtitleLabel.layer.shadowColor = UIColor.black.cgColor
        subtitleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        subtitleLabel.layer.shadowRadius = 2
        subtitleLabel.layer.shadowOpacity = 0.6
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        subtitleLabel.textColor = isFocused ? .white : colorPallete.tertiary
        subtitleLabel.layer.shadowColor = isDark || isFocused ? UIColor.black.cgColor : UIColor.clear.cgColor
    }
    
    #endif
}
