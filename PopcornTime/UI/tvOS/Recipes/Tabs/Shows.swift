

import TVMLKitchen
import PopcornKit

class Shows: TabItem, MediaRecipeDelegate  {
    
    let title = "Shows"
    var recipe: ShowsRecipe!
    
    var index: Int {
        return ActionHandler.shared.tabBar.items.index(where: {$0.title == self.title})!
    }
    
    func handler() {
        if let recipe = recipe {
            // Listeners may have been removed if another tab was navigated to.
            ActionHandler.shared.addListeners(to: recipe, at: index, andPresent: false)
        } else {
            recipe = ShowsRecipe()
            recipe.delegate = self
            recipe.loadNextPage() { [unowned self] _ in
                ActionHandler.shared.addListeners(to: self.recipe, at: self.index, andPresent: true)
            }
        }
    }
    
    func load(page: Int, filter: String, genre: String, completion: @escaping (String?, NSError?) -> Void) {
        guard let filter = ShowManager.Filters(rawValue: filter), let genre = ShowManager.Genres(rawValue: genre) else { return }
        
        PopcornKit.loadShows(page, filterBy: filter, genre: genre) { (shows, error) in
            completion(shows?.map({$0.lockUp}).joined(separator: ""), error)
        }
    }
}
