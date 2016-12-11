

import TVMLKitchen
import PopcornKit

struct Search: TabItem {

    let title = "Search"
    let fetchType: Trakt.MediaType
    
    init(_ type: Trakt.MediaType) {
        fetchType = type
    }

    func handler() {
        Kitchen.serve(recipe: SearchRecipe(fetchType: fetchType))
    }

}
