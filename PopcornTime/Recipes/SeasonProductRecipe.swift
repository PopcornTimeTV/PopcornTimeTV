

import TVMLKitchen
import PopcornKit

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
    public let presentationType = PresentationType.default

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
        return show.actors.map { "<text>\($0.name.cleaned)</text>" }.joined(separator: "")
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

        let actors: [String] = show.actors.map {
            var headshot = ""
            if $0.mediumImage != "http://62.210.81.37/assets/images/actors/default_avatar.jpg" {
                headshot = " src=\"\($0.mediumImage)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showActor»\($0.name)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
            string += "<title>\($0.name.cleaned)</title>" + "\n"
            string += "<subtitle>Actor</subtitle>" + "\n"
            string += "</monogramLockup>" + "\n"
            return string
        }
        
        let directors: [String] = show.crew.filter({ $0.roleType == .Director }).map {
            var headshot = ""
            if $0.mediumImage != "http://62.210.81.37/assets/images/directors/default_avatar.jpg" {
                headshot = " src=\"\($0.mediumImage)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showDirector»\($0.name)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
            string += "<title>\($0.name.cleaned)</title>" + "\n"
            string += "<subtitle>Director</subtitle>" + "\n"
            string += "</monogramLockup>" + "\n"
            return string
        }

        let mapped = actors+directors
        
        return mapped.joined(separator: "\n")
    }

    var watchlistButton: String {
        var string = "<buttonLockup id =\"favoriteButton\" actionID=\"addWatchlist»\(show.id)»\(show.title)»show»\(show.largeCoverImage ?? "")»\(show.largeBackgroundImage ?? "")»\(show.id)»\(show.tvdbId)»\(show.slug)\">\n"
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

    func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    var seasonsButtonTitle: String {
        return "<badge src=\"http://i.cubeupload.com/trh7eQ.png\" width=\"50px\" height=\"37px\"></badge>"
    }

    var seasonsButton: String {
        var string = "<buttonLockup actionID=\"showSeasons»\(show.id)»\(show.slug)»\(show.tvdbId)\">"
        string += "\(seasonsButtonTitle)"
        string += "<title>Series</title>"
        string += "</buttonLockup>"
        return string
    }

    func magnetForEpisode(_ episode: Episode) -> String {
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
            let overview = $0.episode.summary?.cleaned ?? ""
            let fullscreen = $0.fullScreenshot ?? ""
            let mediumscreen = $0.mediumScreenshot ?? ""
            let episodetitle = $0.episodeTitle?.cleaned ?? ""
            let title = show.title?.cleaned ?? ""
            var string = "<lockup actionID=\"playMovie»\(fullscreen)»\(show.largeBackgroundImage ?? "")»\(episodetitle)»\(overview)»\(torrents($0.episode).cleaned)»\($0.episode.id)»\(title)»\($0.episode.episode)»\($0.episode.season)\">" + "\n"
            string += "<img src=\"\(mediumscreen)\" width=\"310\" height=\"175\" />" + "\n"
            string += "<title>\($0.episode.episode). \(episodetitle)</title>" + "\n"
            string += "<overlay class=\"overlayPosition\">" + "\n"
            string += "<badge src=\"resource://button-play\" class=\"whiteButton overlayPosition\"/>" + "\n"
            string += "</overlay>" + "\n"
            string += "<relatedContent>" + "\n"
            string += "<infoTable>" + "\n"
            string +=   "<header>" + "\n"
            string +=       "<title>\(episodetitle)</title>" + "\n"
            string +=       "<description>Episode \($0.episode.episode)</description>" + "\n"
            string +=   "</header>" + "\n"
            string +=   "<info>" + "\n"
            string +=       "<header>" + "\n"
            string +=           "<title>Description</title>" + "\n"
            string +=       "</header>" + "\n"
            string +=       "<description allowsZooming=\"true\" moreLabel=\"more\" actionID=\"showDescription»\(episodetitle)»\(overview)\">\(overview)</description>" + "\n"
            string +=   "</info>" + "\n"
            string += "</infoTable>" + "\n"
            string += "</relatedContent>" + "\n"
            string += "</lockup>" + "\n"
            return string
        }
        return mapped.joined(separator: "\n")
    }

    func torrents(_ episode: Episode) -> String {
        let torrents: [Torrent] = episode.torrents.filter({ $0.quality != "0" })
        let filteredTorrents: [String] = torrents.map { torrent in
            return "quality=\(torrent.quality)&hash=\(torrent.hash)"
        }
        return filteredTorrents.joined(separator: "•")
    }

    public var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "SeasonProductRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)

                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: show.title.cleaned)
                xml = xml.replacingOccurrences(of: "{{SEASON}}", with: seasonString)

                xml = xml.replacingOccurrences(of: "{{RUNTIME}}", with: runtime)
                xml = xml.replacingOccurrences(of: "{{GENRES}}", with: genresString)
                xml = xml.replacingOccurrences(of: "{{DESCRIPTION}}", with: show.summary?.cleaned ?? "")
                xml = xml.replacingOccurrences(of: "{{SHORT_DESCRIPTION}}", with: show.summary?.cleaned ?? "")
                xml = xml.replacingOccurrences(of: "{{IMAGE}}", with: show.largeCoverImage ?? "")
                xml = xml.replacingOccurrences(of: "{{FANART_IMAGE}}", with: show.largeCoverImage ?? "")
                xml = xml.replacingOccurrences(of: "{{YEAR}}", with: show.year.cleaned)
                xml = xml.replacingOccurrences(of: "mpaa-{{RATING}}", with: showInfo.contentRating.lowercased())
                xml = xml.replacingOccurrences(of: "{{AIR_DATE_TIME}}", with: "<text>\(showInfo.airDay)'s \(showInfo.airTime)</text>")

                xml = xml.replacingOccurrences(of: "{{WATCH_LIST_BUTTON}}", with: watchlistButton)
                if existsInWatchList {
                    xml = xml.replacingOccurrences(of: "{{WATCHLIST_ACTION}}", with: "rated")
                } else {
                    xml = xml.replacingOccurrences(of: "{{WATCHLIST_ACTION}}", with: "rate")
                }

                xml = xml.replacingOccurrences(of: "{{EPISODE_COUNT}}", with: episodeCount)
                xml = xml.replacingOccurrences(of: "{{EPISODES}}", with: episodesString)

                xml = xml.replacingOccurrences(of: "{{CAST}}", with: castString)

                xml = xml.replacingOccurrences(of: "{{SEASONS_BUTTON}}", with: seasonsButton)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

}
