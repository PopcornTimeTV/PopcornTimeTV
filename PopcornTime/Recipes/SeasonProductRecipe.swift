

import TVMLKitchen
import PopcornKit
import SWXMLHash

public struct SeasonInfo {
    public var last: Int!
    public var first: Int!
    public var current: Int!
}

public struct DetailedEpisode {
    var episodeTitle: String!
    var episode: Episode!
    var fullScreenshot: String!
    var mediumScreenshot: String!
    var smallScreenshot: String!

    init() {

    }
}

public struct ShowInfo {

    public var airDay: String!
    public var airTime: String
    public var contentRating: String!

    public var cast: [String]!

    public var genres: [String]!

    public var network: String!

    public var runtime: Int!

    public init(xml: XMLIndexer) {
        let seriesInfo = xml["Data"]["Series"]

        self.airDay = seriesInfo["Airs_DayOfWeek"].element!.text!
        self.airTime = seriesInfo["Airs_Time"].element!.text!

        self.contentRating = seriesInfo["ContentRating"].element!.text!

        self.cast = seriesInfo["Actors"].element!.text!.componentsSeparatedByString("|")
        self.cast = self.cast.filter { $0 != "" }

        self.genres = seriesInfo["Genre"].element!.text!.componentsSeparatedByString("|")
        self.genres = self.genres.filter { $0 != "" }

        self.network = seriesInfo["Network"].element!.text!

        self.runtime = Int(seriesInfo["Runtime"].element!.text!)
    }
}

public struct SeasonProductRecipe: RecipeType {

    let show: Show
    let showInfo: ShowInfo
    let episodes: [Episode]
    let detailedEpisodes: [DetailedEpisode]
    let seasonInfo: SeasonInfo
    let existsInWatchList: Bool

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.DefaultWithLoadingIndicator

    public init(show: Show, showInfo: ShowInfo, episodes: [Episode], detailedEpisodes: [DetailedEpisode], seasonInfo: SeasonInfo, existsInWatchlist: Bool) {
        self.show = show
        self.showInfo = showInfo
        self.episodes = episodes
        self.detailedEpisodes = detailedEpisodes
        self.seasonInfo = seasonInfo
        self.existsInWatchList = existsInWatchlist

        AudioManager.sharedManager().playTheme(show.tvdbId)
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    var seasonString: String {
        return "Season \(seasonInfo.current)"
    }

    var actorsString: String {
        return showInfo.cast.map { "<text>\($0.cleaned)</text>" }.joinWithSeparator("")
    }

    var genresString: String {
        if showInfo.genres.count == 3 {
            return "<text>\(showInfo.genres[0])" + "/" + "\(showInfo.genres[1])" + "/" + "\(showInfo.genres[2])</text>"
        } else if showInfo.genres.count == 2 {
            return "<text>\(showInfo.genres[0])" + "/" + "\(showInfo.genres[1])</text>"
        } else {
            return "<text>\(showInfo.genres.first!)</text>"
        }
    }

    var episodeCount: String {
        return "\(episodes.count) Episodes"
    }

    var runtime: String {
        let (_, minutes, _) = self.secondsToHoursMinutesSeconds(showInfo.runtime * 60)
        return "\(minutes)m"
    }

    var castString: String {

        let mapped: [String] = showInfo.cast.map {

            let name = $0.componentsSeparatedByString(" ")
            var string = "<monogramLockup actionID=\"showActor»\($0)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\" src=\"\"/>"
            string += "<title>\($0.cleaned)</title>" + "\n"
            string += "<subtitle>Actor</subtitle>" + "\n"
            string += "</monogramLockup>" + "\n"
            return string
        }

        return mapped.joinWithSeparator("\n")
    }

    var watchlistButton: String {
        var string = "<buttonLockup id =\"favoriteButton\" actionID=\"addWatchlist»\(show.id)»\(show.title)»show»\(show.posterImage)»\(show.fanartImage)»\(show.id)»\(show.tvdbId)»\(show.title.slugged)\">\n"
        string += "<badge id =\"favoriteButtonBadge\" src=\"resource://button-{{WATCHLIST_ACTION}}\" />\n"
        string += "<title>Favourites</title>\n"
        string += "</buttonLockup>"
        return string
    }

    var themeSong: String {
        var s = "<background>\n"
        s += "<audio>\n"
        s += "<asset id=\"tv_theme\" src=\"http://tvthemes.plexapp.com/\(show.tvdbId).mp3\"/>"
        s += "</audio>\n"
        s += "</background>\n"
        return ""
    }

    func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    var seasonsButtonTitle: String {
        return "<badge src=\"http://i.cubeupload.com/trh7eQ.png\" width=\"50px\" height=\"37px\"></badge>"
    }

    var seasonsButton: String {
        var string = "<buttonLockup actionID=\"showSeasons»\(show.id)»\(show.title.slugged)»\(show.tvdbId)\">"
        string += "\(seasonsButtonTitle)"
        string += "<title>Series</title>"
        string += "</buttonLockup>"
        return string
    }

    func magnetForEpisode(episode: Episode) -> String {
        let filteredTorrents = episode.torrents.filter {
            $0.quality == "720p"
        }

        if let first = filteredTorrents.first {
            return first.hash
        } else if let last = episode.torrents.last {
            return last.hash
        }
        return ""
    }

    var episodesString: String {
        let mapped: [String] = detailedEpisodes.map {
            var overview = ""
            if let synopsis = $0.episode.overview {
                overview = synopsis.cleaned
            }
            var string = "<lockup actionID=\"playMovie»\($0.fullScreenshot)»\(show.fanartImage)»\($0.episodeTitle.cleaned)»\(overview)»\(torrents($0.episode).cleaned)»\($0.episode.tvdbId)»\(show.title.cleaned)»\($0.episode.episode)»\($0.episode.season)\">" + "\n"
            string += "<img src=\"\($0.mediumScreenshot)\" width=\"310\" height=\"175\" />" + "\n"
            string += "<title>\($0.episode.episode). \($0.episodeTitle.cleaned)</title>" + "\n"
            string += "<overlay class=\"overlayPosition\">" + "\n"
            string += "<badge src=\"resource://button-play\" class=\"whiteButton overlayPosition\"/>" + "\n"
            string += "</overlay>" + "\n"
            string += "<relatedContent>" + "\n"
            string += "<infoTable>" + "\n"
            string +=   "<header>" + "\n"
            string +=       "<title>\($0.episodeTitle.cleaned)</title>" + "\n"
            string +=       "<description>Episode \($0.episode.episode)</description>" + "\n"
            string +=   "</header>" + "\n"
            string +=   "<info>" + "\n"
            string +=       "<header>" + "\n"
            string +=           "<title>Description</title>" + "\n"
            string +=       "</header>" + "\n"
            string +=       "<description allowsZooming=\"true\" moreLabel=\"more\" actionID=\"showDescription»\($0.episodeTitle.cleaned)»\(overview)\">\(overview)</description>" + "\n"
            string +=   "</info>" + "\n"
            string += "</infoTable>" + "\n"
            string += "</relatedContent>" + "\n"
            string += "</lockup>" + "\n"
            return string
        }
        return mapped.joinWithSeparator("\n")
    }

    func torrents(episode: Episode) -> String {
        let torrents: [Torrent] = episode.torrents.filter({ $0.quality != "0" })
        let filteredTorrents: [String] = torrents.map { torrent in
            return "quality=\(torrent.quality)&hash=\(torrent.hash)"
        }
        return filteredTorrents.joinWithSeparator("•")
    }

    public var template: String {
        var xml = ""
        if let file = NSBundle.mainBundle().URLForResource("SeasonProductRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOfURL: file)

                xml = xml.stringByReplacingOccurrencesOfString("{{TITLE}}", withString: show.title.cleaned)
                xml = xml.stringByReplacingOccurrencesOfString("{{SEASON}}", withString: seasonString)

                xml = xml.stringByReplacingOccurrencesOfString("{{RUNTIME}}", withString: runtime)
                xml = xml.stringByReplacingOccurrencesOfString("{{GENRES}}", withString: genresString)
                xml = xml.stringByReplacingOccurrencesOfString("{{DESCRIPTION}}", withString: show.synopsis!.cleaned)
                xml = xml.stringByReplacingOccurrencesOfString("{{SHORT_DESCRIPTION}}", withString: show.synopsis!.cleaned)
                xml = xml.stringByReplacingOccurrencesOfString("{{IMAGE}}", withString: show.posterImage)
                xml = xml.stringByReplacingOccurrencesOfString("{{FANART_IMAGE}}", withString: show.fanartImage)
                xml = xml.stringByReplacingOccurrencesOfString("{{YEAR}}", withString: "")
                xml = xml.stringByReplacingOccurrencesOfString("mpaa-{{RATING}}", withString: showInfo.contentRating.lowercaseString)
                xml = xml.stringByReplacingOccurrencesOfString("{{AIR_DATE_TIME}}", withString: "<text>\(showInfo.airDay)'s \(showInfo.airTime)</text>")

                xml = xml.stringByReplacingOccurrencesOfString("{{WATCH_LIST_BUTTON}}", withString: watchlistButton)
                if existsInWatchList {
                    xml = xml.stringByReplacingOccurrencesOfString("{{WATCHLIST_ACTION}}", withString: "rated")
                } else {
                    xml = xml.stringByReplacingOccurrencesOfString("{{WATCHLIST_ACTION}}", withString: "rate")
                }

                xml = xml.stringByReplacingOccurrencesOfString("{{EPISODE_COUNT}}", withString: episodeCount)
                xml = xml.stringByReplacingOccurrencesOfString("{{EPISODES}}", withString: episodesString)

                xml = xml.stringByReplacingOccurrencesOfString("{{CAST}}", withString: castString)

                xml = xml.stringByReplacingOccurrencesOfString("{{SEASONS_BUTTON}}", withString: seasonsButton)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
