

import Foundation
import PopcornKit


class ShowsRecipe: MediaRecipe {
    
    override var filter: String {
        return ShowManager.Filters(rawValue: currentFilter)!.string
    }
    
    override var genre: String {
        return currentGenre == "All" ? "" : " " + currentGenre
    }
    
    override var type: String {
        return "Show"
    }
    
    override var watchedlistManager: WatchedlistManager {
        return WatchedlistManager.episode
    }
    
    init() {
        super.init(title: "Shows", defaultGenre: ShowManager.Genres.all.rawValue, defaultFilter: ShowManager.Filters.trending.rawValue)
    }
    
}
