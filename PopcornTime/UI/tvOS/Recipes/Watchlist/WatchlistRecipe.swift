

import TVMLKitchen
import PopcornKit

public struct WatchlistRecipe: RecipeType {

    public let theme = DefaultTheme()
    public var presentationType = PresentationType.default
    
    public let title: String
    public var movies: [Movie]
    public var shows: [Show]

    public init(title: String, movies: [Movie] = [Movie](), shows: [Show] = [Show]()) {
        self.title = title
        self.movies = movies
        self.shows = shows
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    public func mediaString(_ media: [Media]) -> String {
        let mapped: [String] = media.map {
            let type = $0 is Movie ? "Movie" : "Show"
            var string = "<lockup actionID=\"show\(type)»\($0.title)»\($0.id)\">"
            string += "<img class=\"img\" src=\"\($0.mediumCoverImage ?? "")\" width=\"250\" height=\"375\" />"
            string += "<title style=\"tv-text-highlight-style: marquee-and-show-on-highlight;\">\($0.title.cleaned)</title>"
            string += "</lockup>"
            return string
        }
        return mapped.joined(separator: "")
    }

    func buildShelf(_ title: String, content: String) -> String {
        var shelf = "<shelf><header><title>"
        shelf += title
        shelf += "</title></header><section>"
        shelf += content
        shelf += "</section></shelf>"
        return shelf
    }

    public var template: String {
        let isShelf = !movies.isEmpty && !shows.isEmpty
        
        let string: String
        
        if isShelf {
            string = buildShelf("Movies", content: mediaString(movies)) + buildShelf("Shows", content: mediaString(shows))
        } else if !movies.isEmpty {
            string = mediaString(movies)
        } else {
            string = mediaString(shows)
        }
        

        var xml = ""
        if let file = Bundle.main.url(forResource: isShelf ? "WatchlistRecipe" : "CatalogRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: title)
                xml = xml.replacingOccurrences(of: "{{POSTERS}}", with: string)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
