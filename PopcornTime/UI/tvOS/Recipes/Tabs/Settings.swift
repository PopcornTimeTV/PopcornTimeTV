

import TVMLKitchen
import PopcornKit

class Settings: TabItem {
    
    let title = "Settings"
    var viewController: SettingsViewController?

    func handler() {
        // Some hackery to find the main tabBar controller so we can switch out the settings template view controller for our own one.
        guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController,
            let tabBarController = Kitchen.navigationController.viewControllers.first?.templateViewController as? UITabBarController, self.viewController == nil,
            var viewControllers = tabBarController.viewControllers else { return }
        
        self.viewController = viewController
        
        OperationQueue.main.addOperation {
            // Unfortunately replacing the actual view controller is not supported and causes some weirdness with _TVMenuBarController.
            viewControllers[5].view.addSubview(viewController.view)
        }
    }
}
