

import TVMLKitchen

struct Search: TabItem {

    let title = "Search"

    var fetchType: FetchType! = .movies

    func handler() {
        switch self.fetchType! {
        case .movies:
            Kitchen.serve(recipe: YIFYSearchRecipe(type: .tabSearch))

        case .shows:
            Kitchen.serve(recipe: EZTVSearchRecipe(type: .tabSearch))
        }
    }

}
