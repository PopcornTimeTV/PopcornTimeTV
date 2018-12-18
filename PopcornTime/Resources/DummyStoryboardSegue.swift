

import Foundation

/// Dummy storyboard segue for use when you want to programatically control everything about the segue, but still have segue associated methods (`shouldPerformSegue:withIndentifier`, `performSegue:withIdentifier`, `prepareForSegue`).
class DummyStoryboardSegue: UIStoryboardSegue {
    
    override func perform() {
        // Super isn't called so nothing will happen.
    }
}
