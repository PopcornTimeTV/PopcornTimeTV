

import TVMLKitchen
import PopcornKit

class Shows: TabItem, MediaRecipeDelegate  {
    
    let title = "Shows"
    var recipe: ShowsRecipe!
    
    var index: Int {
        return ActionHandler.shared.tabBar.items.index(where: {$0.title == self.title})!
    }
    
    func handler() {
        recipe = recipe ?? {
            let recipe = ShowsRecipe()
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
        guard let filter = ShowManager.Filters(rawValue: filter), let genre = ShowManager.Genres(rawValue: genre) else { return }
        
        PopcornKit.loadShows(page, filterBy: filter, genre: genre) { (shows, error) in
            completion(shows?.map({$0.lockUp}).joined(separator: ""), error)
        }
    }
}
