

import Foundation

extension NSNotification.Name {
    /// Posted when a new `UIView` is focused. The notification `object` contains the views `UIViewController`.
    public static let UIViewControllerFocusedViewDidChange = NSNotification.Name(rawValue: "UIViewControllerFocusedViewDidChange")
}
