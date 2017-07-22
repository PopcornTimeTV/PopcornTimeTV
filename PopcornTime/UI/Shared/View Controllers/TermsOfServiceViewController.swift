

import UIKit

class TermsOfServiceViewController: UIViewController {

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.titleTextAttributes?[NSForegroundColorAttributeName] = UIColor.white
    }
    
    @IBAction func accepted(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: "tosAccepted")
        dismiss(animated: true)
    }
    
    @IBAction func canceled(_ sender: UIButton) {
        exit(0)
    }
}
