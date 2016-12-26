

import TVMLKitchen
import PopcornKit

class Shows: TabItem, MediaRecipeDelegate  {
    
    let title = "Shows"
    var recipe: ShowsRecipe?
    
    func handler() {
        recipe = recipe ?? {
            let recipe = ShowsRecipe()
            recipe.delegate = self
            recipe.loadNextPage() { _ in
                ActionHandler.shared.serveTabRecipe(recipe)
            }
            return recipe
        }()
    }
    
    func load(page: Int, filter: String, genre: String, completion: @escaping (String?, NSError?) -> Void) {
        guard let filter = ShowManager.Filters(rawValue: filter), let genre = ShowManager.Genres(rawValue: genre) else { return }
        
        PopcornKit.loadShows(page, filterBy: filter, genre: genre) { (shows, error) in
            completion(shows?.map({$0.lockUp}).joined(separator: ""), error)
        }
    }
}
