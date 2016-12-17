

import TVMLKitchen
import PopcornKit

struct Latest: TabItem {

    let title = "Recently Released"
    let fetchType: Trakt.MediaType
    
    init(_ type: Trakt.MediaType) {
        fetchType = type
    }
    
    func handler() {
        var recipe: CatalogRecipe!
        switch fetchType {
        case .movies:
            recipe = CatalogRecipe(title: "Recently Released", fetchBlock: { (page, completion) in
                PopcornKit.loadMovies(page, filterBy: .date) { (movies, error) in
                    completion(recipe, movies?.map({$0.lockUp}).joined(separator: ""), error, false)
                }
            })
        case .shows:
            recipe = CatalogRecipe(title: "Recently Released", fetchBlock: { (page, completion) in
                PopcornKit.loadShows(page, filterBy: .date) { (shows, error) in
                    completion(recipe, shows?.map({$0.lockUp}).joined(separator: ""), error, false)
                }
            })
        default: return
        }
    }

}
