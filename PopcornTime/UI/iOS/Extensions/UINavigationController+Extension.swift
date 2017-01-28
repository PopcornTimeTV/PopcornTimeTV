

import Foundation

extension UINavigationController {
    
    /// Pushes a view controller onto the receiver’s stack and updates the display.
    /// The object in the viewController parameter becomes the top view controller on the navigation stack. Pushing a view controller causes its view to be embedded in the navigation interface. If the animated parameter is true, the view is animated into position; otherwise, the view is simply displayed in its final location.
    /// In addition to displaying the view associated with the new view controller at the top of the stack, this method also updates the navigation bar and tool bar accordingly. For information on how the navigation bar is updated, see Updating the Navigation Bar.
    
    /// - Parameter viewControllerToPush:   The view controller to push onto the stack. This object cannot be a tab bar controller. If the view controller is already on the navigation stack, this method throws an exception.
    /// - Parameter flag:                   Pass `true` to animate the presentation; otherwise, pass `false`.
    /// - Parameter completion:             The block to execute after the presentation finishes. This block has no return value and takes no parameters. You may specify `nil` for this parameter.
    public func push(_ viewControllerToPush: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        pushViewController(viewControllerToPush, animated: flag)
        
        guard flag, let coordinator = transitionCoordinator else {
            completion?()
            return
        }
        
        coordinator.animate(alongsideTransition: nil) { _ in completion?() }
    }
    
}
