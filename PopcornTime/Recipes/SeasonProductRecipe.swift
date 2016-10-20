

import TVMLKitchen
import PopcornKit
import ObjectMapper

public struct SeasonProductRecipe: RecipeType {

    let show: Show
    var season: Int

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.default

    public init(show: Show, currentSeason: Int? = nil) {
        self.show = show
        self.season = currentSeason ?? show.seasonNumbers.first!
        if let id = show.tvdbId {
            AudioManager.shared.playTheme(Int(id)!)
        }
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    var seasonString: String {
        return "Season \(season)"
    }

    var actorsString: String {
        return show.actors.map { "<text>\($0.name)</text>" }.joined(separator: "")
    }

    var genresString: String {
        return "<text> \(show.genres.joined(separator: " • ").capitalized)</text>"
    }

    var episodeCount: String {
        return "\(show.episodes.filter({$0.season == season}).count) Episodes"
    }

    var runtime: String {
        return "\(show.runtime ?? "0")m"
    }

    var castString: String {

        let actors: [String] = show.actors.map {
            var headshot = ""
            if let image = $0.mediumImage {
                headshot = " src=\"\(image)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showShowCredits»\($0.name)»\($0.imdbId)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
            string += "<title>\($0.name.cleaned)</title>" + "\n"
            string += "<subtitle>Actor</subtitle>" + "\n"
            string += "</monogramLockup>" + "\n"
            return string
        }
        
        let cast: [String] = show.crew.map {
            var headshot = ""
            if let image = $0.mediumImage {
                headshot = " src=\"\(image)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showMovieCredits»\($0.name)»\($0.imdbId)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
            string += "<title>\($0.name.cleaned)</title>" + "\n"
            string += "<subtitle>\($0.job.cleaned)</subtitle>" + "\n"
            string += "</monogramLockup>" + "\n"
            return string
        }
        let mapped = actors + cast
        return mapped.joined(separator: "\n")
    }

    var watchlistButton: String {
        var string = "<buttonLockup id =\"favoriteButton\" actionID=\"addShowToWatchlist»\(Mapper<Show>().toJSONString(show)?.cleaned ?? "")\">\n"
        string += "<badge id =\"favoriteButtonBadge\" src=\"resource://button-{{WATCHLIST_ACTION}}\" />\n"
        string += "<title>Favourites</title>\n"
        string += "</buttonLockup>"
        return string
    }

    var themeSong: String {
        var s = "<background>\n"
        s += "<audio>\n"
        s += "<asset id=\"tv_theme\" src=\"http://tvthemes.plexapp.com/\(show.tvdbId ?? "").mp3\"/>"
        s += "</audio>\n"
        s += "</background>\n"
        return ""
    }

    var seasonsButtonTitle: String {
        return "<badge src=\"resource://button-season\" width=\"50px\" height=\"37px\"></badge>"
    }

    var seasonsButton: String {
        var string = "<buttonLockup actionID=\"showSeasons»\(Mapper<Show>().toJSONString(show)?.cleaned ?? "")»\(Mapper<Episode>().toJSONString(show.episodes)?.cleaned ?? "")\">"
        string += "\(seasonsButtonTitle)"
        string += "<title>Seasons</title>"
        string += "</buttonLockup>"
        return string
    }

    var episodesString: String {
        let mapped: [String] = show.episodes.filter({$0.season == season}).map {
            var string = "<lockup actionID=\"playMedia»\(Mapper<Torrent>().toJSONString($0.torrents)?.cleaned ?? "")»\(Mapper<Show>().toJSONString(show)?.cleaned ?? "")\">" + "\n"
            string += "<img src=\"\($0.mediumBackgroundImage ?? "")\" width=\"310\" height=\"175\" />" + "\n"
            string += "<title>\($0.episode). \($0.title.cleaned)</title>" + "\n"
            string += "<overlay class=\"overlayPosition\">" + "\n"
            string += "<badge src=\"resource://button-play\" class=\"whiteButton overlayPosition\"/>" + "\n"
            string += "</overlay>" + "\n"
            string += "<relatedContent>" + "\n"
            string += "<infoTable>" + "\n"
            string +=   "<header>" + "\n"
            string +=       "<title>\($0.title.cleaned)</title>" + "\n"
            string +=       "<description>Episode \($0.episode)</description>" + "\n"
            string +=   "</header>" + "\n"
            string +=   "<info>" + "\n"
            string +=       "<header>" + "\n"
            string +=           "<title>Description</title>" + "\n"
            string +=       "</header>" + "\n"
            string +=       "<description allowsZooming=\"true\" moreLabel=\"more\" actionID=\"showDescription»\($0.title.cleaned)»\($0.summary.cleaned)\">\($0.summary.cleaned)</description>" + "\n"
            string +=   "</info>" + "\n"
            string += "</infoTable>" + "\n"
            string += "</relatedContent>" + "\n"
            string += "</lockup>" + "\n"
            return string
        }
        return mapped.joined(separator: "\n")
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
                xml = xml.replacingOccurrences(of: "{{DESCRIPTION}}", with: show.summary.cleaned)
                xml = xml.replacingOccurrences(of: "{{SHORT_DESCRIPTION}}", with: show.summary.cleaned)
                xml = xml.replacingOccurrences(of: "{{IMAGE}}", with: show.largeCoverImage ?? "")
                xml = xml.replacingOccurrences(of: "{{FANART_IMAGE}}", with: show.largeBackgroundImage ?? "")
                xml = xml.replacingOccurrences(of: "{{YEAR}}", with: show.year.cleaned)
                if let day = show.airDay, let time = show.airTime {
                    xml = xml.replacingOccurrences(of: "{{AIR_DATE_TIME}}", with: "<text>\(day)'s at \(time)</text>")
                }

                xml = xml.replacingOccurrences(of: "{{WATCH_LIST_BUTTON}}", with: watchlistButton)
                if WatchlistManager<Show>.show.isAdded(show) {
                    xml = xml.replacingOccurrences(of: "{{WATCHLIST_ACTION}}", with: "remove")
                } else {
                    xml = xml.replacingOccurrences(of: "{{WATCHLIST_ACTION}}", with: "add")
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
