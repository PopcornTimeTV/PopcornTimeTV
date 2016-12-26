

import TVMLKitchen
import PopcornKit

class Movies: TabItem, MediaRecipeDelegate {
    
    let title = "Movies"
    var recipe: MoviesRecipe?
    
    func handler() {
        recipe = recipe ?? {
            let recipe = MoviesRecipe()
            recipe.delegate = self
            recipe.loadNextPage() { _ in
                ActionHandler.shared.serveTabRecipe(recipe)
            }
            return recipe
        }()
    }
    
    func load(page: Int, filter: String, genre: String, completion: @escaping (String?, NSError?) -> Void) {
        guard let filter = MovieManager.Filters(rawValue: filter), let genre = MovieManager.Genres(rawValue: genre) else { return }
        
        PopcornKit.loadMovies(page, filterBy: filter, genre: genre) { (movies, error) in
            completion(movies?.map({$0.lockUp}).joined(separator: ""), error)
        }
    }
}
