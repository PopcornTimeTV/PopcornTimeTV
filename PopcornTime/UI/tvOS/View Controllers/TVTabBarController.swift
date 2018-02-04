

import Foundation


class TVTabBarController: UITabBarController {
    
    var environmentsToFocus: [UIFocusEnvironment] = []
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        defer { environmentsToFocus.removeAll() }
        return environmentsToFocus.isEmpty ? super.preferredFocusEnvironments : environmentsToFocus
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        guard
            let previouslyFocusedView = context.previouslyFocusedView,
            let nextFocusedView = context.nextFocusedView,
            let navigationController = selectedViewController as? TVNavigationController,
            let root = navigationController.topViewController as? MainViewController,
            let collectionView = root.collectionView,
            let items = root.navigationItem.rightBarButtonItems,
            !items.isEmpty,
            collectionView.contentOffset.y + collectionView.contentInset.top < 100 // Make sure we're more or less at the top
        else {
            return true
        }
        
        let previousType = type(of: previouslyFocusedView)
        let nextType = type(of: nextFocusedView)
        
        if (previousType === NSClassFromString("UITabBarButton") && nextType is UICollectionViewCell.Type) || (nextType === NSClassFromString("UITabBarButton") && previousType is UICollectionViewCell.Type) // If the tabBarController is about to loose focus to a collectionViewCell or about to gain focus from a collectionViewCell, focus on the tabBarButtons first.
        {
            environmentsToFocus = items.flatMap({$0.customView}).reversed()
            setNeedsFocusUpdate()
            
            return false
        }
        
        return true
    }
}
