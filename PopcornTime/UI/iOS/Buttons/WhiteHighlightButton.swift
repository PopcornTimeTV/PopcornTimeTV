

import Foundation

@IBDesignable class WhiteHighlightButton: UIButton {
    @IBInspectable var highlightedImageTintColor: UIColor = UIColor.white
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setImage(self.imageView?.image?.withColor(highlightedImageTintColor), for: .highlighted)
    }
    
    override func setImage(_ image: UIImage?, for state: UIControlState) {
        super.setImage(image, for: state)
        super.setImage(image?.withColor(highlightedImageTintColor), for: .highlighted)
    }
}
