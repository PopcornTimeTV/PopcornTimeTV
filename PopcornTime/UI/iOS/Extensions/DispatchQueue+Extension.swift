

import Foundation

typealias DispatchCancelableBlock = (_ cancel: Bool) -> Void

extension DispatchQueue {
    
    func asyncAfter(delay: Double, execute block: @escaping () -> Void) -> DispatchCancelableBlock? {
        var originalBlock: (() -> Void)? = block
        var cancelableBlock: DispatchCancelableBlock? = nil
        let delayBlock: DispatchCancelableBlock = { (cancel: Bool) in
            if let originalBlock = originalBlock, !cancel {
                self.async(execute: originalBlock)
            }
            cancelableBlock = nil
            originalBlock = nil
        }
        cancelableBlock = delayBlock
        asyncAfter(deadline: .now() + delay, execute: {
            cancelableBlock?(false)
        })
        return cancelableBlock
    }
}
