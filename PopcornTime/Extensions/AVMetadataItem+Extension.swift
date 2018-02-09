

import Foundation
import AVFoundation.AVMetadataItem

extension AVMetadataItem {
    
    static func `init`<K: NSCopying & NSObjectProtocol, V: NSCopying & NSObjectProtocol>(key: K, value: V) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = key
        item.locale = .current
        item.keySpace = AVMetadataKeySpace.common
        item.value = value
        
        return item
    }
}
