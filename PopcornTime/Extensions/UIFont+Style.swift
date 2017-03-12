

import Foundation

extension UIFont {
    
    enum Style: String {
        case bold = "Bold"
        case italic = "Italic"
        case boldItalic = "Bold-Italic"
        case normal = "Normal"
        
        static let arrayValue = [bold, italic, boldItalic, normal]
    }
}
