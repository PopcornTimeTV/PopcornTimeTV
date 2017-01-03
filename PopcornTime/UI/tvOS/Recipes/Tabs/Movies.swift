

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
            let group = DispatchGroup()
            recipe.delegate = self
            group.enter()
            recipe.loadNextPage { _ in
                group.leave()
            }
            
            var onDeck: [Movie] = []
            
            for id in WatchedlistManager<Movie>.movie.getOnDeck() {
                group.enter()
                PopcornKit.getMovieInfo(id) { (movie, _) in
                    if let movie = movie { onDeck.append(movie) }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.recipe.onDeck = onDeck
                
                let file = Bundle.main.url(forResource: "MediaRecipe", withExtension: "js")!
                var script = try! String(contentsOf: file)
                script = script.replacingOccurrences(of: "{{RECIPE}}", with: self.recipe.xmlString)
                script = script.replacingOccurrences(of: "{{RECIPE_NAME}}", with: self.recipe.title.lowercased())
                
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
