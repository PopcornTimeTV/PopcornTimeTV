

import Foundation
import PopcornKit

extension DetailViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        ThemeSongManager.shared.stopTheme()
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        if let nextFocusedView = context.nextFocusedView, let tabBarItemViews = tabBarController?.tabBar.subviews.first(where: {$0 is UIScrollView})?.subviews, tabBarItemViews.contains(nextFocusedView) {
            return false
        }
        return true
    }
}
