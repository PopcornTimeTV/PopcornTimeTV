

import Foundation
import GoogleCast.GCKRequest

extension GCKRequest {
    
    private struct AssociatedKeys {
        static var customDataKey = "GCKRequest.customDataKey"
    }
    
    public var customData: Any? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.customDataKey)
        } set (data) {
            objc_setAssociatedObject(self, &AssociatedKeys.customDataKey, data, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
