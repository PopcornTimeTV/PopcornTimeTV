

import UIKit

#if os(tvOS)
    import TVMLKitchen
#endif

class TermsOfServiceViewController: UIViewController {

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func accepted(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: "tosAccepted")
        
        #if os(tvOS)
            OperationQueue.main.addOperation {
                Kitchen.appController.navigationController.popViewController(animated: true)
            }
        #elseif os(iOS)
            dismiss(animated: true, completion: nil)
        #endif
    }
    
    @IBAction func canceled(_ sender: UIButton) {
        exit(0)
    }

}
