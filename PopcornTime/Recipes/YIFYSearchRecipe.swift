

import TVMLKitchen
import PopcornKit

class YIFYSearchRecipe: SearchRecipe {
    override init(type: PresentationType = .search) {
        super.init(type: type)
    }
    
    func filterSearchText(_ text: String, callback: @escaping ((String) -> Void)) {
        PopcornKit.loadMovies(1, filterBy: .popularity, genre: .all, searchTerm: text, orderBy: .descending) { movies, error in
            if let movies = movies {
                let mapped: [String] = movies.map { movie in
                    return movie.lockUp
                }
                
                if let file = Bundle.main.url(forResource: "SearchRecipe", withExtension: "xml") {
                    do {
                        var xml = try String(contentsOf: file)
                        
                        xml = xml.replacingOccurrences(of: "{{TITLE}}", with: "Found \(movies.count) \(movies.count == 1 ? "movie" : "movies") for \"\(text.cleaned)\"")
                        xml = xml.replacingOccurrences(of: "{{RESULTS}}", with: mapped.joined(separator: "\n"))
                        
                        callback(xml)
                    } catch {
                        print("Could not open Catalog template")
                    }
                }
            }
        }
    }

}

class KATSearchRecipe: SearchRecipe {
    fileprivate var currentSearchText = ""
    fileprivate var category = "movies"

    init(type: PresentationType = .search, category: String) {
        super.init(type: type)
        self.category = category
    }

    func filterSearchText(_ text: String, callback: @escaping ((String) -> Void)) {
        currentSearchText = text
        
        NetworkManager.sharedManager().fetchKATResults(page: 1, queryTerm: text, genre: nil, category: self.category, sortBy: "seeders", orderBy: "desc") { movies, error in
            if let movies = movies {
                let mapped: [String] = movies.map { movie in
                    return movie.lockUp
                }

                if let file = NSBundle.mainBundle().URLForResource("KATSearchRecipe", withExtension: "xml") {
                    do {
                        var xml = try String(contentsOfURL: file)

                        xml = xml.stringByReplacingOccurrencesOfString("{{TITLE}}", withString: "Found \(movies.count) \(movies.count == 1 ? "movie" : "movies") for \"\(text.cleaned)\"")
                        xml = xml.stringByReplacingOccurrencesOfString("{{RESULTS}}", withString: mapped.joinWithSeparator("\n"))
                        callback(xml)
                    } catch {
                        print("Could not open Catalog template")
                    }
                }
            }
        }

    }

}

class EZTVSearchRecipe: SearchRecipe {
    var recipe: String? {
        if let file = Bundle.main.url(forResource: "SearchRecipe", withExtension: "xml") {
            do {
                return try String(contentsOf: file)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return nil
    }

    override init(type: PresentationType = .search) {
        super.init(type: type)
    }

    func filterSearchText(_ text: String, callback: @escaping ((String) -> Void)) {
        PopcornKit.loadShows(1, filterBy: .trending, genre: .all, searchTerm: text, orderBy: .descending) { shows, error in
            if let shows = shows {
                let mapped: [String] = shows.map { show in
                    return show.lockUp
                }
                if let recipe = self.recipe {
                    var xml = recipe
                    xml = xml.replacingOccurrences(of: "{{TITLE}}", with: "Found \(shows.count) \(shows.count == 1 ? "show" : "shows") for \"\(text.cleaned)\"")
                    xml = xml.replacingOccurrences(of: "{{RESULTS}}", with: mapped.joined(separator: "\n"))
                    callback(xml)
                }
            }
        }
    }
}
