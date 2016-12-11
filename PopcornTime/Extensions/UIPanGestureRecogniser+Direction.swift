

import Foundation
import UIKit.UIGestureRecognizerSubclass

extension UIPanGestureRecognizer {
    
    enum PanDirection {
        case up
        case down
        case right
        case left
        case unknown
        case none
    }
    
    private struct AssociatedKeys {
        static var direction = "direction"
    }
    
    var direction: PanDirection {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.direction) as? PanDirection ?? .none
        } set (direction) {
            objc_setAssociatedObject(self, &AssociatedKeys.direction, direction, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func pctTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        self.pctTouchesMoved(touches, with: event)
        guard let view = view?.superview else { direction = .unknown; return }
        guard state == .began else {
            switch state {
            case .ended:
                fallthrough
            case .cancelled:
                fallthrough
            case .failed:
                direction = .none
            default: break
            }
            return
        }
        let velocity = self.velocity(in: view)
        
        switch (velocity.x, velocity.y) {
        case (_, let y) where y > 0:
            direction = .down
        case (_, let y) where y < 0:
            direction = .up
        case (let x, _) where x > 0:
            direction = .right
        case (let x, _) where x < 0:
            direction = .left
        default:
            direction = .unknown
        }
    }


    open override class func initialize() {
    
        // make sure this isn't a subclass
        if self !== UIPanGestureRecognizer.self {
            return
        }
    
        DispatchQueue.once {
            let originalMethod = class_getInstanceMethod(self, #selector(touchesMoved(_:with:)))
            let swizzledMethod = class_getInstanceMethod(self, #selector(pctTouchesMoved(_:with:)))
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}
