

import Foundation
import UIKit

extension UIImage {
    
    func rounded(to size: CGSize) -> UIImage? {
        let cornerRadius = size.width/2.0
        let new = copy() as! UIImage
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let layer = CALayer()
        
        layer.frame = CGRect(origin: .zero, size: size)
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        
        layer.contentsGravity = kCAGravityResizeAspectFill
        layer.contents = new.cgImage
        layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return finalImage
    }
    
    func colored(_ color: UIColor?) -> UIImage? {
        let color: UIColor = color ?? .app
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
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
    
    func removingTransparency() -> UIImage? {
        guard
            let cgImage = cgImage,
            let colorSpace = cgImage.colorSpace,
            let bitmapContext = CGContext(data: nil,
                                          width: Int(size.width),
                                          height: Int(size.height),
                                          bitsPerComponent: cgImage.bitsPerComponent,
                                          bytesPerRow: cgImage.bytesPerRow,
                                          space: colorSpace,
                                          bitmapInfo: cgImage.bitmapInfo.rawValue)
            else {
                return nil
        }
    
        bitmapContext.setFillColor(UIColor.white.cgColor)
        bitmapContext.fill(CGRect(origin: .zero, size: size))
        
        bitmapContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
        let image = bitmapContext.makeImage()!
        
        return UIImage(cgImage: image)
    }
    
    func scaled(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let origin = CGPoint(x: (size.width - self.size.width) / 2.0, y: (size.height - self.size.height) / 2.0)
        draw(at: origin)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    /**
     Transforms image to a layer mask.
     
     When the layer is returned, set its frame to the view that the mask is being applied to's frame.
     
     Example usage:
     
         if let layer = imageView.image?.layerMask {
             layer.frame = view.frame
             view.layer.mask = layer
         }
     */
    var layerMask: CALayer? {
        guard
            let copy = copy() as? UIImage,
            let image = copy.colored(.black)?.removingTransparency(), // Image has to have a black foreground on a white background for mask to work.
            let ciImage = CIImage(image: image),
            let filter = CIFilter(name:"CIMaskToAlpha")
            else {
                return nil
        }
        filter.setValue(ciImage, forKey: "inputImage")
        let out = filter.outputImage!
        let layer = CALayer()
        layer.contents = CIContext().createCGImage(out, from: out.extent)
        layer.contentsGravity = kCAGravityCenter
        return layer
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
    
    var isDark: Bool {
        return cgImage?.isDark ?? false
    }
}
