

import Foundation
import PopcornKit

class PersonDetailCollectionViewController: MainViewController {
    
    var currentItem: Person!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = currentItem.name
        collectionViewController.paginated = false
    }
}
