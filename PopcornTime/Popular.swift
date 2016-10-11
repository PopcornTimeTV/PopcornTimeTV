

import TVMLKitchen
import PopcornKit

struct Popular: TabItem {
    
    let title: String
    let fetchType: Trakt.MediaType
    
    init(_ type: Trakt.MediaType) {
        fetchType = type
        switch fetchType {
        case .movies: title = "Top Movies"
        case .shows: title = "Top Shows"
        default: title = ""
        }
    }

    func handler() {
        var recipe: CatalogRecipe!
        switch fetchType {
        case .movies:
            recipe = CatalogRecipe(title: title, fetchBlock: { (page, completion) in
                PopcornKit.loadMovies(page, completion: { (movies, error) in
                    if let movies = movies { completion(movies.map({$0.lockUp}).joined(separator: "")) }
                    ActionHandler.shared.serveCatalogRecipe(recipe)
                })
            })
        case .shows:
            recipe = CatalogRecipe(title: title, fetchBlock: { (page, completion) in
                PopcornKit.loadShows(page, completion: { (shows, error) in
                    if let shows = shows { completion(shows.map({$0.lockUp}).joined(separator: "")) }
                    ActionHandler.shared.serveCatalogRecipe(recipe)
                })
            })
        default: return
        }
    }
}
