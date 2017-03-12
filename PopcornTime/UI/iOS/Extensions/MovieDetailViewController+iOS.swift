

import Foundation

extension MovieDetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let watchedButton = UIBarButtonItem(image: watchedButtonImage, style: .plain, target: self, action: #selector(self.toggleWatched(_:)))
        
        navigationItem.rightBarButtonItems?.insert(watchedButton, at: 0)
    }
    
    func toggleWatched(_ sender: UIBarButtonItem) {
        movie.isWatched = !movie.isWatched
        sender.image = watchedButtonImage
    }
}
