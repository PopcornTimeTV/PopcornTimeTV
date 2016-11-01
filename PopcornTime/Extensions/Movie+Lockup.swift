

import PopcornKit
import ObjectMapper

extension Movie {

    var lockUp: String {
        var string = "<lockup actionID=\"showMovie»\(title.cleaned)»\(id)\" playActionID=\"chooseQuality»\(Mapper<Torrent>().toJSONString(torrents)?.cleaned ?? "")»\(Mapper<Movie>().toJSONString(self)?.cleaned ?? "")\">"
        string += "<img class=\"img\" src=\"\(smallCoverImage ?? "")\" width=\"250\" height=\"375\" />"
        string += "<title style=\"tv-text-highlight-style: marquee-and-show-on-highlight;\">\(title.cleaned)</title>"
        string += "</lockup>"
        return string
    }

    var lockUpGenre: String {
        let string = "<img class=\"img\" src=\"\(smallCoverImage ?? "")\" width=\"250\" height=\"375\" />"
        return string
    }

}
