

import TVMLKitchen
import PopcornKit

class Watchlist: TabItem {

    let title = "Watchlist"
    var recipe: WatchlistRecipe!
    
    func handler() {
        recipe = recipe ?? {
            var recipe = WatchlistRecipe(title: title)
            
            recipe.movies = WatchlistManager<Movie>.movie.getWatchlist { (movies) in
                self.recipe.movies = movies
            }
            
            recipe.shows = WatchlistManager<Show>.show.getWatchlist { (shows) in
                self.recipe.shows = shows
            }
            
            if recipe.shows.isEmpty && recipe.movies.isEmpty {
                let backgroundView = ErrorBackgroundView()
                backgroundView.setUpView(title: "Watchlist Empty", description: "Try adding shows to your watchlist")
                Kitchen.serve(xmlString: backgroundView.xmlString, type: .tab)
                return recipe
            }
            
            
            Kitchen.serve(recipe: recipe)
            
            return recipe
        }()
    }

}
