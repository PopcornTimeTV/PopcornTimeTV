

import TVMLKitchen
import PopcornKit

@objc class SearchRecipe: NSObject, SearchRecipeType, SearchRecipeJSExports {
    
    dynamic var doc: JSValue?
    
    var fetchType: Trakt.MediaType = .movies
    
    var results: String {
        let file = Bundle.main.url(forResource: "SearchRecipe", withExtension: "xml")!
        return try! String(contentsOf: file)
    }
    
    var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }
    
    var template: String {
        let file = Bundle.main.url(forResource: "SearchTemplate", withExtension: "xml")!
        return try! String(contentsOf: file)
    }
    
    var noData: String {
        return "<list> <section> <header> <title>No Results</title> </header> </section> </list>"
    }
    
    func filterSearchText(_ text: String, callback: @escaping ((String) -> Void)) {
        guard !text.isEmpty else { callback(noData); return }
        
        var results = self.results
        
        switch fetchType {
        case .movies:
            PopcornKit.loadMovies(searchTerm: text) { movies, error in
                guard let movies = movies else { callback(self.noData); return }
                let mapped = movies.map({ $0.lockUp })
                
                results = results.replacingOccurrences(of: "{{TITLE}}", with: "Found \(movies.count) \(movies.count == 1 ? "movie" : "movies") for \"\(text.cleaned)\"").replacingOccurrences(of: "{{RESULTS}}", with: mapped.joined(separator: ""))
                
                callback(results)
            }
        case .shows:
            PopcornKit.loadShows(searchTerm: text) { shows, error in
                guard let shows = shows else { callback(self.noData); return }
                let mapped = shows.map({ $0.lockUp })
                
                results = results.replacingOccurrences(of: "{{TITLE}}", with: "Found \(shows.count) \(shows.count == 1 ? "show" : "shows") for \"\(text.cleaned)\"").replacingOccurrences(of: "{{RESULTS}}", with: mapped.joined(separator: ""))
                
                callback(results)
            }
        case .people:
            TraktManager.shared.search(forPerson: text) { (people, error) in
                guard let people = people else { callback(self.noData); return }
                let mapped: [String] = people.map({
                    var headshot = ""
                    if let image = $0.mediumImage {
                        headshot = " src=\"\(image)\""
                    }
                    let name = $0.name.components(separatedBy: " ")
                    var string = "<monogramLockup actionID=\"showCredits»\($0.name)»\($0.imdbId)\">" + "\n"
                    string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
                    string += "<title>\($0.name.cleaned)</title>" + "\n"
                    string += "</monogramLockup>" + "\n"
                    return string
                })
                
                results = results.replacingOccurrences(of: "{{TITLE}}", with: "Found \(people.count) \(people.count == 1 ? "person" : "people") for \"\(text.cleaned)\"").replacingOccurrences(of: "{{RESULTS}}", with: mapped.joined(separator: ""))
                
                callback(results)
            }
        default:
            return
        }
    }
    
    func segmentBarDidChangeSegment(_ rawValue: String) {
        fetchType = Trakt.MediaType(rawValue: rawValue)!
    }
}
