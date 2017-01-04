

import TVMLKitchen
import PopcornKit
import ObjectMapper

public struct WatchlistRecipe: RecipeType {

    public let theme = DefaultTheme()
    public var presentationType = PresentationType.tab
    
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
            var string = ""
            if let movie = $0 as? Movie {
                string = "<lockup actionID=\"showMovie»\(Mapper<Movie>().toJSONString(movie)?.cleaned ?? "")»\(false)\">"
                string += "<img style=\"tv-placeholder: movie;\" src=\"\($0.smallCoverImage ?? "")\" width=\"250\" height=\"375\" />"
            } else if let show = $0 as? Show {
                string = "<lockup actionID=\"showShow»\(Mapper<Show>().toJSONString(show)?.cleaned ?? "")»\">"
                string += "<img style=\"tv-placeholder: tv;\" src=\"\($0.smallCoverImage ?? "")\" width=\"250\" height=\"375\" />"
            }
            string += "<title style=\"tv-text-highlight-style: marquee-and-show-on-highlight;\">\($0.title.cleaned)</title>"
            string += "</lockup>"
            return string
        }
        return mapped.joined(separator: "")
    }

    func buildShelf(_ title: String, content: String) -> String {
        guard !content.isEmpty else { return "" }
        var shelf = "<shelf><header><title>"
        shelf += title
        shelf += "</title></header><section>"
        shelf += content
        shelf += "</section></shelf>"
        return shelf
    }

    public var template: String {
        
        let shelves = buildShelf("Movies", content: mediaString(movies)) + buildShelf("Shows", content: mediaString(shows))

        let file = Bundle.main.url(forResource: "WatchlistRecipe", withExtension: "xml")!
        var xml = try! String(contentsOf: file)
        xml = xml.replacingOccurrences(of: "{{TITLE}}", with: title)
        xml = xml.replacingOccurrences(of: "{{SHELVES}}", with: shelves)
        
        return xml
    }

}
