

import Foundation
import PopcornKit

class ShowContainerViewController: UIViewController {
    
    var currentItem: Show!
    var currentType: Trakt.MediaType = .shows
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail", let vc = (segue.destination as? UISplitViewController)?.viewControllers.first as? ShowDetailViewController {
            vc.currentItem = currentItem
            vc.currentType = currentType
            vc.parentTabBarController = tabBarController
            vc.parentNavigationController = navigationController
            navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems
            vc.parentNavigationItem = navigationItem
        }
    }
}
