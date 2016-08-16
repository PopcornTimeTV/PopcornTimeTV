

import PopcornKit

extension Movie {

    var lockUp: String {
        var string = "<lockup actionID=\"showMovie»\(id)\" playActionID=\"playMovieById»\(id)\">"
        string += "<img class=\"img\" src=\"\(mediumCoverImage)\" width=\"250\" height=\"375\" />"
        string += "<title style=\"tv-text-highlight-style: marquee-and-show-on-highlight;\">\(title.cleaned)</title>"
        string += "</lockup>"
        return string
    }

    var lockUpGenre: String {
        let string = "<img class=\"img\" src=\"\(mediumCoverImage)\" width=\"250\" height=\"375\" />"
        return string
    }

}

extension KATResult {



    var torrents: String {
        let filteredTorrents: [String] = self.torrents.map { torrent in
            return "quality=\(torrent.quality)&hash=\(torrent.hash)"
        }
        return filteredTorrents.joinWithSeparator("•")
    }

    var lockUp: String {
        var string = "<listItemLockup style=\"tv-align:left; width:100%;\" actionID=\"playMovie»{{IMAGE}}»{{BACKGROUND_IMAGE}}»\(title.cleaned)»{{SHORT_DESCRIPTION}}»\(torrents.cleaned)»{{IMDBID}}\">"
        //string += "<img src=\"\(mediumCoverImage)\" width=\"250\" height=\"375\" />"
        string += "<title>\(title.cleaned)</title>"
        string += "</listItemLockup>"
        return string
    }

}
