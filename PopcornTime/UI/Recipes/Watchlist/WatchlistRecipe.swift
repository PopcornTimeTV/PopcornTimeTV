

import TVMLKitchen
import PopcornKit

public struct WatchlistRecipe: RecipeType {

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.default
    
    let title: String
    var watchListMovies: [Movie]
    var watchListShows: [Show]

    init(title: String, watchListMovies: [Movie] = [Movie](), watchListShows: [Show] = [Show]()) {
        self.title = title
        self.watchListMovies = watchListMovies
        self.watchListShows = watchListShows
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    public var moviesWatchList: String {
        let mapped = watchListMovies.map { movie -> String in
            var string = "<lockup actionID=\"showMovie»\(movie.title.cleaned)»\(movie.id)\" playActionID=\"playMovieById»\(movie.id)\" >"
            string += "<img src=\"\(movie.mediumCoverImage ?? "")\" width=\"250\" height=\"375\" />"
            string += "<title class=\"hover\">\(movie.title.cleaned)</title>"
            string += "</lockup>"
            return string
        }
        return mapped.joined(separator: "\n")
    }

    public var showsWatchList: String {
        let mapped = watchListShows.map { show -> String in
            var string = "<lockup actionID=\"showShow»\(show.id)»\(show.slug)»\(show.tvdbId)\" playActionID=\"showShow»\(show.id)»\(show.slug)»\(show.tvdbId)\">"
            string += "<img src=\"\(show.mediumCoverImage ?? "")\" width=\"250\" height=\"375\" />"
            string += "<title class=\"hover\">\(show.title.cleaned)</title>"
            string += "</lockup>"
            return string
        }
        return mapped.joined(separator: "\n")
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
        var shelfs = ""
        shelfs += self.buildShelf("Movies", content: moviesWatchList)
        shelfs += self.buildShelf("Shows", content: showsWatchList)

        var xml = ""
        if let file = Bundle.main.url(forResource: "WatchlistRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: title)
                xml = xml.replacingOccurrences(of: "{{SHELFS}}", with: shelfs)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
