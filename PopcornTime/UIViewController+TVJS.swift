

import Foundation
import TVMLKitchen

extension UIViewController {
    
    func pctViewDidDisappear(_ animated: Bool) {
        Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
            if let function = context.objectForKeyedSubscript("viewDidDisappear"), !function.isUndefined {
                function.call(withArguments: [])
            }
            }, completion: nil)
        self.pctViewDidDisappear(animated)
    }
    
    func pctViewDidAppear(_ animated: Bool) {
        Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
            if let function = context.objectForKeyedSubscript("viewDidAppear"), !function.isUndefined {
                function.call(withArguments: [])
            }
            }, completion: nil)
        self.pctViewDidAppear(animated)
    }
    
    open override class func initialize() {
        
        // make sure this isn't a subclass
        if self !== UIViewController.self {
            return
        }
        
        DispatchQueue.once {
            exchangeImplementations(originalSelector: #selector(viewDidDisappear(_:)), swizzledSelector: #selector(pctViewDidDisappear(_:)))
            exchangeImplementations(originalSelector: #selector(viewDidAppear(_:)), swizzledSelector: #selector(pctViewDidAppear(_:)))
        }
    }
    
    class func exchangeImplementations(originalSelector: Selector, swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
