

import TVMLKitchen
import PopcornKit

class Movies: TabItem, MediaRecipeDelegate {
    
    let title = "Movies"
    var recipe: MoviesRecipe!
    
    var index: Int {
        return ActionHandler.shared.tabBar.items.index(where: {$0.title == self.title})!
    }
    
    func handler() {
        if let recipe = recipe {
            // Listeners may have been removed if another tab was navigated to.
            ActionHandler.shared.addListeners(to: recipe, at: index, andPresent: false)
        } else {
            recipe = MoviesRecipe()
            recipe.delegate = self
            recipe.loadNextPage() { [unowned self] _ in
                ActionHandler.shared.addListeners(to: self.recipe, at: self.index, andPresent: true)
            }
        }
    }
    
    func load(page: Int, filter: String, genre: String, completion: @escaping (String?, NSError?) -> Void) {
        guard let filter = MovieManager.Filters(rawValue: filter), let genre = MovieManager.Genres(rawValue: genre) else { return }
        
        PopcornKit.loadMovies(page, filterBy: filter, genre: genre) { (movies, error) in
            completion(movies?.map({$0.lockUp}).joined(separator: ""), error)
        }
    }
}
