

import Foundation
import PopcornKit

extension MovieDetailViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        ThemeSongManager.shared.playMovieTheme(movie.title)
    }
}
