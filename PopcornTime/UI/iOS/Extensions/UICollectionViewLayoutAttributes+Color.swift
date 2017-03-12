

import Foundation

extension UICollectionViewLayoutAttributes {
    
    private struct AssociatedKeys {
        static var colorKey = "UICollectionViewLayoutAttributes.colorKey"
    }
    
    var color: UIColor? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.colorKey) as? UIColor
        } set {
            objc_setAssociatedObject(self, &AssociatedKeys.colorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
