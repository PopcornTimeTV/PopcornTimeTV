

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
    
    func value(forKeyPath path: String) -> Any? {
        let keys = path.components(separatedBy: ".")
        
        var latestValue: Any? = self
        
        for key in keys {
            if let objectValue = latestValue as? NSObject {
                latestValue = objectValue.value(forKey: key)
            } else if let structValue = latestValue as? KVC {
                latestValue = structValue.value(forKey: key)
            } else {
                break
            }
        }
        
        return latestValue
    }
}
