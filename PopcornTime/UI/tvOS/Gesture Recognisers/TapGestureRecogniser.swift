

import Foundation
import UIKit.UIGestureRecognizerSubclass

class IRTapGestureRecogniser: UITapGestureRecognizer {
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        presses.forEach { (press) in
            if press.isSynthetic { ignore(press, for: event) }
        }
        super.pressesBegan(presses, with: event)
    }
}

extension UIPress {
    @nonobjc var isSynthetic: Bool {
        guard let value = value(forKey: "_isSynthetic") as? Bool else { return false }
        return value
    }
}
