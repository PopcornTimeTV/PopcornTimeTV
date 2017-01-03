

import Foundation
import PopcornKit


class MoviesRecipe: MediaRecipe {
    
    override var filter: String {
        return MovieManager.Filters(rawValue: currentFilter)!.string
    }
    
    override var genre: String {
        return currentGenre == "All" ? "" : " " + currentGenre
    }
    
    override var type: String {
        return "Movie"
    }
    
    override var continueWatchingLockup: String {
        return onDeck.map {
            var xml = "<lockup id=\"continueWatchingLockup\" actionID=\"showMovie»\($0.title.cleaned)»\($0.id)\">" + "\n"
<<<<<<< Updated upstream
            xml +=      "<img src=\"\($0.mediumBackgroundImage ?? "")\" width=\"850\" height=\"350\" />" + "\n"
=======
            xml +=      "<img class=\"overlayGradient\" src=\"\($0.largeBackgroundImage ?? "")\" width=\"850\" height=\"350\" />" + "\n"
>>>>>>> Stashed changes
            xml +=      "<overlay>" + "\n"
            xml +=          "<title class=\"overlayTitle\">\($0.title)</title>" + "\n"
            xml +=          "<progressBar value=\"\(WatchedlistManager<Movie>.movie.currentProgress($0 as! Movie))\" class=\"bar\" />" + "\n"
            xml +=     "</overlay>" + "\n"
            xml +=  "</lockup>" + "\n"
            return xml
            }.joined(separator: "")
    }
    
    init() {
        super.init(onDeck: WatchedlistManager<Movie>.movie.getOnDeck(),title: "Movies", defaultGenre: MovieManager.Genres.all.rawValue, defaultFilter: MovieManager.Filters.trending.rawValue)
    }
    
}
