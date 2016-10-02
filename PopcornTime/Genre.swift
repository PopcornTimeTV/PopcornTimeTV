

import TVMLKitchen
import PopcornKit

struct Genre: TabItem {

    var title = "Genre"

    var fetchType: FetchType! = .movies {
        didSet {
            if let _ = self.fetchType {
                switch self.fetchType! {
                case .movies: title = "Genre"
                case .shows: title = "Genre"

                }
            }
        }
    }

    func handler() {
        switch self.fetchType! {
        case .movies:
            NetworkManager.sharedManager().fetchMovies(limit: 50, page: 1, quality: "1080p", minimumRating: 3, queryTerm: nil, genre: nil, sortBy: "seeds", orderBy: "desc") { movies, error in
                if movies != nil {
                    let recipe = GenreRecipe(fetchType: self.fetchType)
                    self.serveRecipe(recipe)
                }
            }
        case .shows:
            let manager = NetworkManager.sharedManager()
            manager.fetchShowPageNumbers { pageNumbers, error in
                if let _ = pageNumbers {
                    // this is temporary limit until solve pagination
                    manager.fetchShows([1], sort: "trending") { shows, error in
                        if shows != nil {
                            let recipe = GenreRecipe(fetchType: self.fetchType)
                            self.serveRecipe(recipe)
                        }
                    }
                }
            }
        }
    }


    func serveRecipe(_ recipe: GenreRecipe) {
        Kitchen.appController.evaluateInJavaScriptContext({jsContext in
            let highlightSection: @convention(block) (String, JSValue) -> () = {(text, callback) in
                recipe.highlightSection(text) { string in
                    if callback.isObject {
                        callback.callWithArguments([string])
                    }
                }
            }

            jsContext.setObject(unsafeBitCast(highlightSection, AnyObject.self), forKeyedSubscript: "highlightSection")

            if let file = NSBundle.mainBundle().URLForResource("Genre", withExtension: "js") {
                do {
                    var js = try String(contentsOfURL: file)
                    js = js.stringByReplacingOccurrencesOfString("{{RECIPE}}", withString: recipe.xmlString)
                    jsContext.evaluateScript(js)
                } catch {
                    print("Could not open Genre.js")
                }
            }

            }, completion: nil)
    }
}
