

import UIKit

class TermsOfServiceViewController: UIViewController {

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func accepted(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: "tosAccepted")
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func canceled(_ sender: UIButton) {
        exit(0)
    }

}
