

import Foundation

extension DispatchQueue {
    
    @nonobjc private static var _onceTracker = [String]()
    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - Parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID. Defaults to device UUID.
     - Parameter block: Block to execute once
     */
    public class func once(token: String = UUID().uuidString, block: () -> Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}
