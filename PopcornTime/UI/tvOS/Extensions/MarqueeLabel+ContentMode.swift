

import Foundation
import MarqueeLabel

extension MarqueeLabel: Object {
    
    static func awake() {
        DispatchQueue.once {
            let originalMethod = class_getInstanceMethod(self, #selector(awakeFromNib))
            let swizzledMethod = class_getInstanceMethod(self, #selector(pctAwakeFromNib))
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
    
    @objc func pctAwakeFromNib() {
        self.pctAwakeFromNib()
        
        if let iVar = class_getInstanceVariable(Swift.type(of: self), NSString(string: "sublabel").utf8String!),
            let label = object_getIvar(self, iVar) as? UILabel {
            label.contentMode = contentMode
        }
    }
}
