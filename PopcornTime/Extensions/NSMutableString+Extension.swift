

import Foundation

extension NSMutableAttributedString {
    
    @discardableResult func color(_ textToFind: String, _ color: UIColor) -> Bool {
        let range = mutableString.range(of: textToFind, options: .caseInsensitive)
        
        guard range.location != NSNotFound else { return false }
        
        addAttribute(NSForegroundColorAttributeName, value: color, range: range)
        
        return true
    }
}

func attributedString(with spacing: Int = 25, between images: String...) -> [NSAttributedString] {
    return images.flatMap({
        guard let attributedString = UIImage(named: $0)?.colored(.white).attributed else { return nil }
        
        let string = NSMutableAttributedString(attributedString: attributedString)
        string.append(UIImage.from(color: .clear, size: CGSize(width: spacing, height: 1)).attributed)
        
        return string
    })
}
