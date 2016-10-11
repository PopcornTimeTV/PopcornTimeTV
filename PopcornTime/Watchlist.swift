

import TVMLKitchen
import PopcornKit

struct Watchlist: TabItem {

    let title = "Favourites"
    let fetchType: Trakt.MediaType
    
    init(_ type: Trakt.MediaType) {
        fetchType = type
    }

    func handler() {
        switch fetchType {
        case .movies:
            var recipe = MovieWatchlistRecipe(title: title, movies: [Movie]())
            recipe.items = WatchlistManager<Movie>.movie.getWatchlist({ (movies) in
                recipe.items = movies
            })
            Kitchen.serve(recipe: recipe)
        case .shows:
            var recipe = ShowWatchlistRecipe(title: title, shows: [Show]())
            recipe.items = WatchlistManager<Show>.show.getWatchlist({ (shows) in
                recipe.items = shows
            })
            Kitchen.serve(recipe: recipe)
            
        default:
            break
        }
    }

}
