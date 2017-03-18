

import Foundation

extension MovieDetailViewController {
    
    var watchedButtonImage: UIImage? {
        return movie.isWatched ? UIImage(named: "Watched On") : UIImage(named: "Watched Off")
    }
    
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
