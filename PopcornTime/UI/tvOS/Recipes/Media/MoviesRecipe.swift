

import Foundation
import PopcornKit


class MoviesRecipe: MediaRecipe {
    
    override var filter: String {
        return MovieManager.Filters(rawValue: currentFilter)!.string
    }
    
    override var genre: String {
        return currentGenre == "All" ? "" : currentGenre
    }
    
    override var type: String {
        return "Movie"
    }
    
    override var watchedlistManager: WatchedlistManager {
        return WatchedlistManager.movie
    }
    
    init() {
        super.init(title: "Movies", defaultGenre: MovieManager.Genres.all.rawValue, defaultFilter: MovieManager.Filters.trending.rawValue)
    }
    
}
