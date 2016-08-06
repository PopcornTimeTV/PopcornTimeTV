

import TVMLKitchen

struct Watchlist: TabItem {

    let title = "Watchlist"

    var fetchType: FetchType! = .Movies

    func handler() {
        switch self.fetchType! {
        case .Movies:
            WatchlistManager.sharedManager().fetchWatchListItems(forType: .Movie) { items in
                Kitchen.serve(recipe: MovieWatchlistRecipe(title: self.title, movies: items))
            }

        case .Shows:
            WatchlistManager.sharedManager().fetchWatchListItems(forType: .Show) { items in
                Kitchen.serve(recipe: ShowWatchlistRecipe(title: self.title, movies: items))
            }
        }

    }

}
