

import Foundation
import UIKit

extension UIColor {
    func hexString() -> String {
        let colorSpace = self.cgColor.colorSpace?.model
        let components = self.cgColor.components
        
        var r, g, b: CGFloat!
        
        if (colorSpace == .monochrome) {
            r = components?[0]
            g = components?[0]
            b = components?[0]
        } else if (colorSpace == .rgb) {
            r = components?[0]
            g = components?[1]
            b = components?[2]
        }
        
        return NSString(format: "#%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255)) as String
    }
    
    func hexInt() -> UInt32 {
        let hex = hexString()
        var rgb: UInt32 = 0
        let s = Scanner(string: hex)
//        s.scanLocation = 1
//        s.scanHexInt32(&rgb)
        //deprecated in tvos 13.0
        return rgb
    }
    
    @nonobjc var localizedString: String? {
        switch self {
        case UIColor.black:
            return "Black".localized
        case UIColor.darkGray:
            return "Dark Gray".localized
        case UIColor.lightGray:
            return "Light Gray".localized
        case UIColor.white:
            return "White".localized
        case UIColor.gray:
            return "Gray".localized
        case UIColor.red:
            return "Red".localized
        case UIColor.green:
            return "Green".localized
        case UIColor.blue:
            return "Blue".localized
        case UIColor.cyan:
            return "Cyan".localized
        case UIColor.yellow:
            return "Yellow".localized
        case UIColor.magenta:
            return "Magenta".localized
        case UIColor.orange:
            return "Orange".localized
        case UIColor.purple:
            return "Purple".localized
        case UIColor.brown:
            return "Brown".localized
        default:
            return nil
        }
    }
    
    @nonobjc static var systemColors: [UIColor] {
        return [UIColor.black, UIColor.darkGray, UIColor.lightGray, UIColor.white, UIColor.gray, UIColor.red, UIColor.green, UIColor.blue, UIColor.cyan, UIColor.yellow, UIColor.magenta, UIColor.orange, UIColor.purple, UIColor.brown]
    }
    
    @nonobjc static var app: UIColor {
        return UIDevice.current.userInterfaceIdiom == .tv ? .white : UIColor(red: 0.37, green: 0.41, blue: 0.91, alpha: 1.0)
    }
    
    @nonobjc static let dark = UIColor(red: 28.0/255.0, green: 28.0/255.0, blue: 28.0/255.0, alpha: 1.0)
}
