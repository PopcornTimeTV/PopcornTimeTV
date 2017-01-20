

import Foundation
import PopcornKit
import ObjectMapper


class ShowsRecipe: MediaRecipe {
    
    override var filter: String {
        return ShowManager.Filters(rawValue: currentFilter)!.string
    }
    
    override var genre: String {
        return currentGenre == "All" ? "" : " " + currentGenre
    }
    
    override var type: String {
        return "Show"
    }
    
    override var continueWatchingLockup: String {
        return onDeck.map {
            guard let episode = $0 as? Episode else { return "" }
            var xml = "<lockup id=\"continueWatchingLockup\" actionID=\"showShow»\(Mapper<Show>().toJSONString(episode.show)?.cleaned ?? "")»\(Mapper<Episode>().toJSONString(episode)?.cleaned ?? "")\">" + "\n"
            xml +=      "<img class=\"overlayGradient\" src=\"\(episode.mediumBackgroundImage ?? "")\" width=\"850\" height=\"350\" />" + "\n"
            xml +=      "<overlay>" + "\n"
            xml +=          "<title class=\"overlayTitle\">\(episode.title.cleaned)</title>" + "\n"
            xml +=          "<subtitle class=\"overlaySubtitle\">\(episode.show.title.cleaned): S\(episode.season):E\(episode.episode)</subtitle>" + "\n"
            xml +=          "<progressBar value=\"\(WatchedlistManager<Episode>.episode.currentProgress(episode.id))\" class=\"bar\" />" + "\n"
            xml +=     "</overlay>" + "\n"
            xml +=  "</lockup>" + "\n"
            return xml
        }.joined(separator: "")
    }
    
    init() {
        super.init(title: "Shows", defaultGenre: ShowManager.Genres.all.rawValue, defaultFilter: ShowManager.Filters.trending.rawValue)
    }
    
}
