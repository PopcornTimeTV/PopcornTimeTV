

import Foundation
import PopcornKit
import ObjectMapper


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
            guard let movie = $0 as? Movie else { return "" }
            var xml = "<lockup id=\"continueWatchingLockup\" actionID=\"showMovie»\(Mapper<Movie>().toJSONString(movie)?.cleaned ?? "")»\(true)\">" + "\n"
            xml +=      "<img class=\"overlayGradient\" src=\"\(movie.mediumBackgroundImage ?? "")\" width=\"850\" height=\"350\" />" + "\n"
            xml +=      "<overlay>" + "\n"
            xml +=          "<title class=\"overlayTitle\">\(movie.title)</title>" + "\n"
            xml +=          "<progressBar value=\"\(WatchedlistManager<Movie>.movie.currentProgress(movie.id))\" class=\"bar\" />" + "\n"
            xml +=     "</overlay>" + "\n"
            xml +=  "</lockup>" + "\n"
            return xml
        }.joined(separator: "")
    }
    
    init() {
        super.init(title: "Movies", defaultGenre: MovieManager.Genres.all.rawValue, defaultFilter: MovieManager.Filters.trending.rawValue)
    }
    
}
