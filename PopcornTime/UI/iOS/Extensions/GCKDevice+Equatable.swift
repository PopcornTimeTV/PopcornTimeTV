

import Foundation
import GoogleCast.GCKDevice

extension GCKDevice {
    
    open override func isEqual(_ object: Any?) -> Bool {
        if let lhs = object as? GCKDevice {
            let rhs = self
            return lhs.deviceID == rhs.deviceID && lhs.uniqueID == rhs.uniqueID
        }
        return false
    }
}
