

import TVMLKitchen
import PopcornKit

struct Genre: TabItem {
    var title = "Genre"

    var fetchType: FetchType = .movies {
        didSet {
            switch self.fetchType {
            case .movies: title = "Genre"
            case .shows: title = "Genre"
            }
        }
    }

    func handler() {
        switch fetchType {
        case .movies:
            PopcornKit.loadMovies(1) { movies, error in
                if movies != nil {
                    let recipe = GenreRecipe(type: self.fetchType)
                    self.serveRecipe(recipe)
                }
            }
            
        case .shows:
            PopcornKit.loadShows(1, filterBy: .trending, genre: .all, searchTerm: nil, orderBy: .descending) { shows, error in
                if shows != nil {
                    let recipe = GenreRecipe(type: self.fetchType)
                    self.serveRecipe(recipe)
                }
            }
        }
    }


    func serveRecipe(_ recipe: GenreRecipe) {
        Kitchen.appController.evaluate(inJavaScriptContext: {jsContext in
            let highlightSection: @convention(block) (String, JSValue) -> () = {(text, callback) in
                recipe.section(didHighlightWithGenre: text) { string in
                    if callback.isObject {
                        callback.call(withArguments: [string])
                    }
                }
            }

            jsContext.setObject(unsafeBitCast(highlightSection, to: AnyObject.self), forKeyedSubscript: "highlightSection" as NSString)

            if let file = Bundle.main.url(forResource: "Genre", withExtension: "js") {
                do {
                    var js = try String(contentsOf: file)
                    js = js.replacingOccurrences(of: "{{RECIPE}}", with: recipe.xmlString)
                    jsContext.evaluateScript(js)
                } catch {
                    print("Could not open Genre.js")
                }
            }

            }, completion: nil)
    }
}
