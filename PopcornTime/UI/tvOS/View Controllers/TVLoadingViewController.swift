

import Foundation

class TVLoadingViewController: UIViewController {
    
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var visualEffectView: UIVisualEffectView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
    class func with(backgroundImage: String?, title: String) -> TVLoadingViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let `self` = storyboard.instantiateViewController(withIdentifier: "TVLoadingViewController") as! TVLoadingViewController
        
        self.loadView()
        
        if let image = backgroundImage, let url = URL(string: image) {
            self.backgroundImageView.af_setImage(withURL: url)
        }
        
        self.titleLabel.text = title
        
        return self
    }
}
