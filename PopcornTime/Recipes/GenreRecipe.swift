

import TVMLKitchen
import PopcornKit

public struct GenreRecipe: RecipeType {

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.Tab
    var type: Trakt.MediaType = .movies
    var currentPage = 0

    init(type: Trakt.MediaType = .movies) {
        self.type = type
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    public var listItems: String {
        switch type {
        case .movies:
            let mappedListItem = MovieManager.Genres.array.map {
                let listItem = "<listItemLockup actionID=\"showGenre»\($0)»movie\" sectionID=\"\($0)\"> \n" +
                             "<title>\($0)</title> \n" +
                             "<relatedContent> \n" +
                             "<imgDeck id=\"\($0)\"></imgDeck> \n" +
                             "</relatedContent> \n" +
                             "</listItemLockup>"
                return listItem
            }
            return mappedListItem.joined(separator: "\n")
        case .shows:
            let mappedListItem = ShowManager.Genres.array.map {
                let listItem = "<listItemLockup actionID=\"showGenre»\($0)»show\" sectionID=\"\($0)\"> \n" +
                    "<title>\($0)</title> \n" +
                    "<relatedContent> \n" +
                    "<imgDeck id=\"\($0)\"></imgDeck> \n" +
                    "</relatedContent> \n" +
                "</listItemLockup>"
                return listItem
            }
            return mappedListItem.joined(separator: "\n")
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
    
    public func section(didHighlightWithGenre genre: String, completion: (String) -> Void) {
        switch type {
        case .movies:
            guard let genre = MovieManager.Genres(rawValue: genre) else { return }
            PopcornKit.loadMovies(currentPage, genre: genre) { (movies, error) in
                guard let movies = movies else { return }
                let mapped = movies.map { $0.lockUpGenre }
                completion(mapped.joinWithSeparator("\n"))
            }
        case .shows:
            guard let genre = Show.Genres(rawValue: genre) else { return }
            PopcornKit.loadShows(currentPage, genre: genre, completion: { (shows, error) in
                guard let shows = shows else { return }
                let mapped = shows.map { $0.lockUpGenre }
                completion(mapped.joinWithSeparator("\n"))
            })
        }
    }
}
