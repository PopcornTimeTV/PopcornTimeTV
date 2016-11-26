

import TVMLKitchen
import PopcornKit

struct Watchlist: TabItem {

    let title = "Watchlist"
    let fetchType: Trakt.MediaType
    
    init(_ type: Trakt.MediaType) {
        fetchType = type
    }

    func handler() {
        switch fetchType {
        case .movies:
            var recipe = WatchlistRecipe(title: title, movies: [Movie]())
            recipe.movies = WatchlistManager<Movie>.movie.getWatchlist({ (movies) in
                recipe.movies = movies
            })
            recipe.presentationType = .tab
            Kitchen.serve(recipe: recipe)
        case .shows:
            var recipe = WatchlistRecipe(title: title, shows: [Show]())
            recipe.shows = WatchlistManager<Show>.show.getWatchlist({ (shows) in
                recipe.shows = shows
            })
            recipe.presentationType = .tab
            Kitchen.serve(recipe: recipe)
        default:
            break
        }
    }

}
