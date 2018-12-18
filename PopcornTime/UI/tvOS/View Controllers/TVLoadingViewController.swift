

import Foundation

class TVLoadingViewController: UIViewController {
    
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var visualEffectView: UIVisualEffectView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var focusButton: UIButton!
    
    override var preferredFocusEnvironments: [UIFocusEnvironment]{
        focusButton.frame.origin.y = focusButton.frame.origin.y + 20
        return [focusButton]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsFocusUpdate()
    }
    
}
