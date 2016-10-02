

import TVMLKitchen

struct Watchlist: TabItem {

    let title = "Favourites"

    var fetchType: FetchType = .movies

    func handler() {
        switch fetchType {
        case .movies:
            WatchlistManager.sharedManager().fetchWatchListItems(forType: .Movie) { items in
                Kitchen.serve(recipe: MovieWatchlistRecipe(title: self.title, movies: items))
            }

        case .shows:
            WatchlistManager.sharedManager().fetchWatchListItems(forType: .Show) { items in
                Kitchen.serve(recipe: ShowWatchlistRecipe(title: self.title, movies: items))
            }
        }

    }

}
