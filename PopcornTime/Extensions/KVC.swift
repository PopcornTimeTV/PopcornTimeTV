

import Foundation

protocol KVC {
    func value(forKey key: String) -> Any?
}

extension KVC {
    
    func value(forKey key: String) -> Any? {
        let mirror = Mirror(reflecting: self)
        
        for (childKey, childValue) in mirror.children where childKey == key {
            return childValue
        }
        
        return nil
    }
}
