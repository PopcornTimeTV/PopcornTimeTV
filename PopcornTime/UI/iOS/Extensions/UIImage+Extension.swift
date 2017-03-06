

import Foundation
import UIKit

extension UIImage {
    
    func rounded(to size: CGSize) -> UIImage? {
        let cornerRadius = size.width/2.0
        let new = copy() as! UIImage
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let layer = CALayer()
        
        layer.frame = CGRect(origin: .zero, size: size)
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        layer.contentsGravity = "resizeAspectFill"
        layer.contents = new.cgImage
        layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return finalImage
    }
    
    func colored(_ color: UIColor?) -> UIImage? {
        let color: UIColor = color ?? .app
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext(), let cgImage = cgImage else { return nil }
        color.setFill()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.colorBurn)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context.draw(cgImage, in: rect)
        context.setBlendMode(.sourceIn)
        context.addRect(rect)
        context.drawPath(using: .fill)
        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return coloredImage
    }
    
    class func from(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    var attributed: NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = self
        attachment.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        return NSAttributedString(attachment: attachment)
    }
    
}
