

import TVMLKitchen
import PopcornKit

class Movies: TabItem, MediaRecipeDelegate {
    
    let title = "Movies"
    var recipe: MoviesRecipe!
    
    var index: Int {
        return ActionHandler.shared.tabBar.items.index(where: {$0.title == self.title})!
    }
    
    func handler() {
        recipe = recipe ?? {
            let recipe = MoviesRecipe()
            recipe.delegate = self
            recipe.loadNextPage { _ in
                let file = Bundle.main.url(forResource: "MediaRecipe", withExtension: "js")!
                var script = try! String(contentsOf: file)
                script = script.replacingOccurrences(of: "{{RECIPE}}", with: recipe.xmlString)
                script = script.replacingOccurrences(of: "{{RECIPE_NAME}}", with: recipe.title.lowercased())
                
                ActionHandler.shared.evaluate(script: script)
            }
            return recipe
        }()
        
        ActionHandler.shared.mediaRecipe = recipe
    }
    
    func load(page: Int, filter: String, genre: String, completion: @escaping (String?, NSError?) -> Void) {
        guard let filter = MovieManager.Filters(rawValue: filter), let genre = MovieManager.Genres(rawValue: genre) else { return }
        
        PopcornKit.loadMovies(page, filterBy: filter, genre: genre) { (movies, error) in
            completion(movies?.map({$0.lockUp}).joined(separator: ""), error)
        }
    }
}
