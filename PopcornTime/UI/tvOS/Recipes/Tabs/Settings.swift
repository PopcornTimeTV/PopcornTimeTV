

import TVMLKitchen

class Settings: TabItem {
    
    let title = "Settings"
    var viewController: SettingsViewController?

    func handler() {
        viewController = viewController ?? ActionHandler.shared.addViewController(with: "SettingsViewController", of: SettingsViewController.self, at: 4)
    }
}
