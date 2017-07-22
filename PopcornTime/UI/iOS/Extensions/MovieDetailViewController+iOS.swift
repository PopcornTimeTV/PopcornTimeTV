

import Foundation

extension MovieDetailViewController {
    
    @IBAction func toggleWatched(_ sender: UIButton) {
        movie.isWatched = !movie.isWatched
        sender.setImage(watchedButtonImage, for: .normal)
    }
}
