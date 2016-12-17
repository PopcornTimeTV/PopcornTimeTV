

import TVMLKitchen
import PopcornKit

struct Watchlist: TabItem {

    let title = "Watchlist"
    let fetchType: Trakt.MediaType
    
    init(_ type: Trakt.MediaType) {
        fetchType = type
    }

    func handler() {
        var recipe: WatchlistRecipe
        switch fetchType {
        case .movies:
            recipe = WatchlistRecipe(title: title, movies: [Movie]())
            recipe.movies = WatchlistManager<Movie>.movie.getWatchlist({ (movies) in
                recipe.movies = movies
            })
            guard !recipe.movies.isEmpty else {
                let backgroundView = ErrorBackgroundView()
                backgroundView.setUpView(title: "Watchlist Empty", description: "Try adding movies to your watchlist")
                Kitchen.serve(xmlString: backgroundView.xmlString, type: .tab)
                return
            }
        case .shows:
            recipe = WatchlistRecipe(title: title, shows: [Show]())
            recipe.shows = WatchlistManager<Show>.show.getWatchlist({ (shows) in
                recipe.shows = shows
            })
            
            guard !recipe.shows.isEmpty else {
                let backgroundView = ErrorBackgroundView()
                backgroundView.setUpView(title: "Watchlist Empty", description: "Try adding shows to your watchlist")
                Kitchen.serve(xmlString: backgroundView.xmlString, type: .tab)
                return
            }
            
        default: return
        }
        recipe.presentationType = .tab
        Kitchen.serve(recipe: recipe)
    }

}
