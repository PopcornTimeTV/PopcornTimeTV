

import TVMLKitchen
import PopcornKit

class SearchRecipe: TVMLKitchen.SearchRecipe {
    
    var fetchType: Trakt.MediaType = .movies
    
    init() {
        super.init()
        try? (UIApplication.shared.delegate as! AppDelegate).cookbook.set(value: self, key: "searchRecipe")
    }
    
    var recipe: String? {
        let file = Bundle.main.url(forResource: "SearchRecipe", withExtension: "xml")!
        return try! String(contentsOf: file)
    }
    
    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }
    
    public var template: String {
        let file = Bundle.main.url(forResource: "SearchTemplate", withExtension: "xml")!
        return try! String(contentsOf: file)
    }
    
    override func filterSearchText(_ text: String, callback: @escaping ((String) -> Void)) {
        guard !text.isEmpty else { callback(noData); return }
        
        switch fetchType {
        case .movies:
            PopcornKit.loadMovies(searchTerm: text) { movies, error in
                guard let movies = movies, var xml = self.recipe else { callback(self.noData); return }
                let mapped = movies.map({ $0.lockUp })
                
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: "Found \(movies.count) \(movies.count == 1 ? "movie" : "movies") for \"\(text.cleaned)\"").replacingOccurrences(of: "{{RESULTS}}", with: mapped.joined(separator: ""))
                
                callback(xml)
            }
        case .shows:
            PopcornKit.loadShows(searchTerm: text) { shows, error in
                guard let shows = shows, var xml = self.recipe else { callback(self.noData); return }
                let mapped = shows.map({ $0.lockUp })
                
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: "Found \(shows.count) \(shows.count == 1 ? "show" : "shows") for \"\(text.cleaned)\"").replacingOccurrences(of: "{{RESULTS}}", with: mapped.joined(separator: ""))
                
                callback(xml)
            }
        default:
            return
        }
    }
}
