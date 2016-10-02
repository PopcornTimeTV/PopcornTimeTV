

import TVMLKitchen
import PopcornKit

struct Latest: TabItem {

    let title = "Recently Released"
    var fetchType: FetchType! = .movies

    func handler() {
        switch self.fetchType! {
        case .movies:
            PopcornKit.loadMovies(1, filterBy: .year, genre: .all, searchTerm: nil, orderBy: .descending) { movies, error in
                if let movies = movies {
                    let recipe = CatalogRecipe(title: "Recently Released", movies: movies)
                    self.serveRecipe(recipe)
                }
            }
        case .shows:
            PopcornKit.loadShows(1, filterBy: .year, genre: .all, searchTerm: nil, orderBy: .descending) { shows, error in
                if let shows = shows {
                    let recipe = CatalogRecipe(title: "Recently Released", shows: shows)
                    recipe.fetchType = .shows
                    recipe.sortBy = .year
                    self.serveRecipe(recipe)
                }
            }
        }
    }

    func serveRecipe(_ recipe: CatalogRecipe) {
        Kitchen.appController.evaluate(inJavaScriptContext: {jsContext in
            let highlightLockup: @convention(block) (Int, JSValue) -> () = {(nextPage, callback) in
                recipe.lockup(didHighlightWithPage: nextPage) { string in
                    if callback.isObject {
                        callback.call(withArguments: [string])
                    }
                }
            }
            
            jsContext.setObject(unsafeBitCast(highlightLockup, to: AnyObject.self), forKeyedSubscript: "highlightLockup" as NSString)
            
            if let file = Bundle.main.url(forResource: "Pagination", withExtension: "js") {
                do {
                    var js = try String(contentsOf: file)
                    js = js.replacingOccurrences(of: "{{RECIPE}}", with: recipe.xmlString)
                    jsContext.evaluateScript(js)
                } catch {
                    print("Could not open Pagination.js")
                }
            }
            
            }, completion: nil)
    }

}
