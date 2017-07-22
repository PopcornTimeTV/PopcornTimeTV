

import Foundation

@IBDesignable class WhiteHighlightButton: UIButton {
    
    @IBInspectable var highlightedImageTintColor: UIColor = .white
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setImage(imageView?.image?.colored(highlightedImageTintColor), for: .highlighted)
    }
}
