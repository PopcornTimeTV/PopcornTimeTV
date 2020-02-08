

import Foundation

class SidePanelIntroduction: UIView {
    
    @IBAction func didPressBackButton(_ sender: UITapGestureRecognizer){
        if sender.state == .ended{
            UserDefaults.standard.set(true, forKey: "informedForViewChanges")
            UIView.animate(withDuration: 0.4) {
                (self.parent as? MainViewController)?.sidePanelConstraint?.constant = 0
                self.superview?.layoutIfNeeded()
                self.removeFromSuperview()
            }
        }
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        super.shouldUpdateFocus(in: context)
        return false
    }
    
    
}
