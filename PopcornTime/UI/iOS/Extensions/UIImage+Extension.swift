

import Foundation
import UIKit

extension UIImage {
    
    func colored(_ color: UIColor?) -> UIImage {
        let color: UIColor = color ?? .app
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        color.setFill()
        context?.translateBy(x: 0, y: size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.colorBurn)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context?.draw(cgImage!, in: rect)
        context?.setBlendMode(CGBlendMode.sourceIn)
        context?.addRect(rect)
        context?.drawPath(using: CGPathDrawingMode.fill)
        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return coloredImage!
    }
    
    class func from(color: UIColor?, inRect rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> UIImage {
        let color: UIColor = color ?? UIColor.app
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    var attributed: NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = self
        return NSAttributedString(attachment: attachment)
    }
    
}

func attributedString(from images: String...) -> [NSAttributedString] {
    return images.flatMap({
        guard let attributedString = UIImage(named: $0)?.colored(.white).attributed else { return nil }
        
        let string = NSMutableAttributedString(attributedString: attributedString)
        string.append(NSAttributedString(string: "\t"))
        
        return string
    })
}
