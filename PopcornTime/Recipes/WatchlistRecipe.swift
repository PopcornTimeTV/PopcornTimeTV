

import TVMLKitchen
import PopcornKit

public struct WatchlistRecipe: RecipeType {

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.DefaultWithLoadingIndicator

    let title: String
    let watchListMovies: [WatchItem]
    let watchListShows: [WatchItem]

    init(title: String, watchListMovies: [WatchItem], watchListShows: [WatchItem]) {
        self.title = title
        self.watchListMovies = watchListMovies
        self.watchListShows = watchListShows
    }

    init(title: String) {
        self.title = title
        self.watchListMovies = []
        self.watchListShows = []
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    public var moviesWatchList: String {
        let mapped: [String] = watchListMovies.map {
            var string = "<lockup actionID=\"showMovie»\($0.id)\" playActionID=\"playMovieById»\($0.id)\" >"
            string += "<img src=\"\($0.coverImage)\" width=\"250\" height=\"375\" />"
            string += "<title class=\"hover\">\($0.name.cleaned)</title>"
            string += "</lockup>"
            return string
        }
        return mapped.joinWithSeparator("\n")
    }

    public var showsWatchList: String {
        let mapped: [String] = watchListShows.map {
            var string = "<lockup actionID=\"showShow»\($0.id)»\($0.slugged)»\($0.tvdbId)\" playActionID=\"showShow»\($0.id)»\($0.slugged)»\($0.tvdbId)\">"
            string += "<img src=\"\($0.coverImage)\" width=\"250\" height=\"375\" />"
            string += "<title class=\"hover\">\($0.name.cleaned)</title>"
            string += "</lockup>"
            return string
        }
        return mapped.joinWithSeparator("\n")
    }

    func buildShelf(title: String, content: String) -> String {
        var shelf = "<shelf><header><title>"
        shelf += title
        shelf += "</title></header><section>"
        shelf += content
        shelf += "</section></shelf>"
        return shelf
    }

    public var template: String {
        var shelfs = ""
        shelfs += self.buildShelf("Movies Watchlist", content: moviesWatchList)
        shelfs += self.buildShelf("TV Shows Watchlist", content: showsWatchList)

        var xml = ""
        if let file = NSBundle.mainBundle().URLForResource("WatchlistRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOfURL: file)
                xml = xml.stringByReplacingOccurrencesOfString("{{TITLE}}", withString: title)
                xml = xml.stringByReplacingOccurrencesOfString("{{SHELFS}}", withString: shelfs)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
