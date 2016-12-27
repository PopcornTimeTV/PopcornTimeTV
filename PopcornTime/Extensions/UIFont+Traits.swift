

import Foundation

extension UIFont {
    
    enum FontStyle: String {
        case bold = "Bold"
        case italic = "Italic"
        case boldItalic = "Bold-Italic"
        case normal = "Normal"
        
        static let arrayValue = [bold, italic, boldItalic, normal]
    }
    
    func withTraits(_ traits: UIFontDescriptorSymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor
            .withSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
    
    var boldItalic: UIFont {
        return withTraits(.traitBold, .traitItalic)
    }
    
    var bold: UIFont {
        return withTraits(.traitBold)
    }
    
    var italic: UIFont {
        return withTraits(.traitItalic)
    }
}
