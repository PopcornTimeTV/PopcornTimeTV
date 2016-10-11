

import TVMLKitchen
import PopcornKit

class SearchRecipe: TVMLKitchen.SearchRecipe {
    
    let fetchType: Trakt.MediaType
    
    init(fetchType: Trakt.MediaType) {
        self.fetchType = fetchType
        super.init()
    }
    
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
    
    override func filterSearchText(_ text: String, callback: ((String) -> Void)) {
        var searchXML = ""
        let semaphore = DispatchSemaphore(value: 0)
        
        switch fetchType {
        case .movies:
            PopcornKit.loadMovies(searchTerm: text) { movies, error in
                guard let movies = movies, var xml = self.recipe else { semaphore.signal(); return }
                let mapped = movies.map({ $0.lockUp })
                
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: "Found \(movies.count) \(movies.count == 1 ? "movie" : "movies") for \"\(text.cleaned)\"").replacingOccurrences(of: "{{RESULTS}}", with: mapped.joined(separator: "\n"))
                
                searchXML = xml
                
                semaphore.signal()
            }
        case .shows:
            PopcornKit.loadShows(searchTerm: text) { shows, error in
                guard let shows = shows, var xml = self.recipe else { semaphore.signal(); return }
                let mapped = shows.map({ $0.lockUp })
                
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: "Found \(shows.count) \(shows.count == 1 ? "show" : "shows") for \"\(text.cleaned)\"").replacingOccurrences(of: "{{RESULTS}}", with: mapped.joined(separator: "\n"))
                
                searchXML = xml
                
                semaphore.signal()
            }
        default: return
        }
        semaphore.wait()
        callback(searchXML)
    }
}
