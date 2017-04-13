

import Foundation

fileprivate extension UILayoutPriority {
    /// Lowest possible value. Do not interact with anything
    static let `default`: UILayoutPriority = 1
    /// Highest possible value when setting constraints programatically.
    static let required: UILayoutPriority = 999
}

extension UICollectionViewCell {
    
    private struct AssociatedKeys {
        static var focusedConstraintsKey = "UICollectionViewCell.focusedConstraintsKey"
    }
    
    var focusedConstraints: [NSLayoutConstraint] {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.focusedConstraintsKey) as? [NSLayoutConstraint] ?? []
        } set (constraints) {
            objc_setAssociatedObject(self, &AssociatedKeys.focusedConstraintsKey, constraints, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    open override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        focusedConstraints.forEach({
            $0.priority = self.isFocused ? .required : .default
            $0.isActive = true
        })
        
        coordinator.addCoordinatedAnimations({
            self.layoutIfNeeded()
        })
    }
}
