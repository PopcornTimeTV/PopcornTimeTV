

import Foundation

extension MovieDetailViewController {
    
    var watchedButtonImage: UIImage? {
        return movie.isWatched ? UIImage(named: "Watched On") : UIImage(named: "Watched Off")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        watchedButton?.setImage(watchedButtonImage, for: .normal)
    }
    
    @IBAction func toggleWatched(_ sender: UIButton) {
        movie.isWatched = !movie.isWatched
        sender.setImage(watchedButtonImage, for: .normal)
    }
}
