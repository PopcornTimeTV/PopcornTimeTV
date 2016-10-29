

import TVMLKitchen
import PopcornKit

public struct GenreRecipe: RecipeType {
    public let theme = DefaultTheme()
    public let presentationType = PresentationType.tab
    let fetchType: Trakt.MediaType
    var currentPage = 1

    init(fetchType: Trakt.MediaType) {
        self.fetchType = fetchType
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    public var listItems: String {
        switch fetchType {
        case .movies:
            let mappedListItem: [String] = MovieManager.Genres.array.map {
                let listItem = "<listItemLockup actionID=\"showMovieGenre»\($0.rawValue)\" sectionID=\"\($0.rawValue)\"> \n" +
                             "<title>\($0.rawValue)</title> \n" +
                             "<relatedContent> \n" +
                             "<imgDeck id=\"\($0.rawValue)\"></imgDeck> \n" +
                             "</relatedContent> \n" +
                             "</listItemLockup>"
                return listItem
            }
            return mappedListItem.joined(separator: "\n")
        case .shows:
            let mappedListItem: [String] = ShowManager.Genres.array.map {
                let listItem = "<listItemLockup actionID=\"showShowGenre»\($0.rawValue)\" sectionID=\"\($0.rawValue)\"> \n" +
                    "<title>\($0.rawValue)</title> \n" +
                    "<relatedContent> \n" +
                    "<imgDeck id=\"\($0.rawValue)\"></imgDeck> \n" +
                    "</relatedContent> \n" +
                "</listItemLockup>"
                return listItem
            }
            return mappedListItem.joined(separator: "\n")
        default:
            return ""
        }
    }

    public var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "GenreRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.replacingOccurrences(of: "{{LIST_ITEMS}}", with: listItems)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }
    
    public func section(didHighlightWithGenre genre: String, completion: @escaping (String) -> Void) {
        switch fetchType {
        case .movies:
            guard let genre = MovieManager.Genres(rawValue: genre) else { return }
            PopcornKit.loadMovies(currentPage, genre: genre) { (movies, error) in
                guard let movies = movies else { return }
                let mapped = movies.map { $0.lockUpGenre }
                completion(mapped.joined(separator: "\n"))
            }
        case .shows:
            guard let genre = ShowManager.Genres(rawValue: genre) else { return }
            PopcornKit.loadShows(currentPage, genre: genre, completion: { (shows, error) in
                guard let shows = shows else { return }
                let mapped = shows.map { $0.lockUpGenre }
                completion(mapped.joined(separator: "\n"))
            })
        default: break
        }
    }
}
