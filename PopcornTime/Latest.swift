

import TVMLKitchen
import PopcornKit

struct Latest: TabItem {

    let title = "Recently Released"
    var fetchType: FetchType! = .Movies

    func handler() {
        switch self.fetchType! {
        case .Movies:
            NetworkManager.sharedManager().fetchMovies(limit: 50, page: 1, quality: "1080p", minimumRating: 0, queryTerm: nil, genre: nil, sortBy: "year", orderBy: "desc") { movies, error in
                if let movies = movies {
                    let recipe = CatalogRecipe(title: "Recently Released", movies: movies)
                    self.serveRecipe(recipe)
                }
            }
        case .Shows:
            let manager = NetworkManager.sharedManager()
            manager.fetchShowPageNumbers { pageNumbers, error in
                if let _ = pageNumbers {
                    // this is temporary limit until solve pagination
                    manager.fetchShows([1], sort: "updated") { shows, error in
                        if let shows = shows {
                            let recipe = CatalogRecipe(title: "Recently Released", shows: shows.sort({ show1, show2 -> Bool in
                                if let date1 = show1.lastUpdated, let date2 = show2.lastUpdated {
                                    return date1 < date2
                                }
                                return true
                            }))
                            recipe.fetchType = .Shows
                            recipe.sortBy = "updated"
                            self.serveRecipe(recipe)
                        }
                    }
                }
            }
        }
    }

    func serveRecipe(recipe: CatalogRecipe) {
        Kitchen.appController.evaluateInJavaScriptContext({jsContext in
            let highlightLockup: @convention(block) (Int, JSValue) -> () = {(nextPage, callback) in
                recipe.highlightLockup(nextPage) { string in
                    if callback.isObject {
                        callback.callWithArguments([string])
                    }
                }
            }

            jsContext.setObject(unsafeBitCast(highlightLockup, AnyObject.self), forKeyedSubscript: "highlightLockup")

            if let file = NSBundle.mainBundle().URLForResource("Pagination", withExtension: "js") {
                do {
                    var js = try String(contentsOfURL: file)
                    js = js.stringByReplacingOccurrencesOfString("{{RECIPE}}", withString: recipe.xmlString)
                    jsContext.evaluateScript(js)
                } catch {
                    print("Could not open Pagination.js")
                }
            }

            }, completion: nil)
    }

}
