

import TVMLKitchen
import PopcornKit

public struct WatchlistRecipe: RecipeType {

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.Default
    
    let title: String
    let watchListMovies: [Movie]
    let watchListShows: [Show]

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
        let mapped = watchListMovies.map {
            var string = "<lockup actionID=\"showMovie»\($0.id)\" playActionID=\"playMovieById»\($0.id)\" >"
            string += "<img src=\"\($0.coverImage)\" width=\"250\" height=\"375\" />"
            string += "<title class=\"hover\">\($0.name.cleaned)</title>"
            string += "</lockup>"
            return string
        }
        return mapped.joined(separator: "\n")
    }

    public var showsWatchList: String {
        let mapped = watchListShows.map {
            var string = "<lockup actionID=\"showShow»\($0.id)»\($0.slugged)»\($0.tvdbId)\" playActionID=\"showShow»\($0.id)»\($0.slugged)»\($0.tvdbId)\">"
            string += "<img src=\"\($0.coverImage)\" width=\"250\" height=\"375\" />"
            string += "<title class=\"hover\">\($0.name.cleaned)</title>"
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
