

import TVMLKitchen
import PopcornKit

class Search: TabItem {

    let title = "Search"
    var recipe: SearchRecipe!

    func handler() {
        recipe = recipe ?? {
            let recipe = SearchRecipe()
            
            ActionHandler.shared.searchRecipe = recipe
            
            let file = Bundle.main.url(forResource: "SearchRecipe", withExtension: "js")!
            let script = try! String(contentsOf: file).replacingOccurrences(of: "{{RECIPE}}", with: recipe.xmlString)
            
            ActionHandler.shared.evaluate(script: script)
            
            return recipe
        }()
    }
}
