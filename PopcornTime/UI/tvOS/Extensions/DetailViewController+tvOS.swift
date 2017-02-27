

import Foundation
import PopcornKit

extension DetailViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopTheme), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startTheme), name: .UIApplicationWillEnterForeground, object: nil)
        
        startTheme()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopTheme()
        NotificationCenter.default.removeObserver(self)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        if let nextFocusedView = context.nextFocusedView, let tabBarItemViews = tabBarController?.tabBar.subviews.first(where: {$0 is UIScrollView})?.subviews, tabBarItemViews.contains(nextFocusedView) {
            return false
        }
        return true
    }
    
    func stopTheme() {
        ThemeSongManager.shared.stopTheme()
    }
    
    func startTheme() {
        if let movie = currentItem as? Movie {
            ThemeSongManager.shared.playMovieTheme(movie.title)
        } else if let show = currentItem as? Show {
            ThemeSongManager.shared.playShowTheme(Int(show.tvdbId)!)
        }
    }
}
