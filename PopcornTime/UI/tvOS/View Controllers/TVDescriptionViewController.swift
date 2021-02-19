

import Foundation

class TVDescriptionViewController: UIViewController {
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet weak var blurBox: UIVisualEffectView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        blurBox?.layer.cornerRadius = 20
        blurBox?.clipsToBounds = true
    }
}
