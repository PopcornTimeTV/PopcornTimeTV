

import Foundation

extension ShowDetailViewController: SeasonPickerViewControllerDelegate {

    
    override func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is SeasonPickerViewController {
            return TVBlurOverCurrentContextAnimatedTransitioning(isPresenting: true)
        }
        return super.animationController(forPresented: presented, presenting: presenting, source: source)
        
    }
    
    override func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is SeasonPickerViewController {
            return TVBlurOverCurrentContextAnimatedTransitioning(isPresenting: false)
        }
        return super.animationController(forDismissed: dismissed)
    }
    
}
