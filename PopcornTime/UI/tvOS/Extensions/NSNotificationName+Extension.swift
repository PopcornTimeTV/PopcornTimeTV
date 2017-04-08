

import Foundation

extension Notification.Name {
    /// Posted when a new `UIView` is focused. The notification `object` contains the view's `UIViewController`.
    public static let UIViewControllerFocusedViewDidChange = Notification.Name(rawValue: "UIViewControllerFocusedViewDidChange")
    
    /// Posted when a new route becomes discoverable or an existing route becomes unavailable. The notification `object` contains the associated `MSVDistributedNotificationObserver` instance.
    public static let AVSpeakerManagerPickableRoutesDidChange = Notification.Name(rawValue: "kMRMediaRemotePickableRoutesDidChangeNotification")
}
