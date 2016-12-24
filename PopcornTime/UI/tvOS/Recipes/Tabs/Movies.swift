

import TVMLKitchen
import PopcornKit

class Movies: TabItem {
    
    let title = "Movies"
    var recipe: MoviesRecipe?
    
    func handler() {
        recipe = recipe ?? MoviesRecipe { (filter, genre, page, completion) in
            PopcornKit.loadMovies(page, filterBy: filter, genre: genre) { (movies, error) in
                completion(movies?.map({$0.lockUp}).joined(separator: ""), error)
            }
        }
    }
}
