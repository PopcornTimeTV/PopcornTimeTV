

import PopcornKit
import ObjectMapper

extension Show {

    var lockUp: String {
        var string = "<lockup actionID=\"showShow»\(Mapper<Show>().toJSONString(self)?.cleaned ?? "")»\">"
        string += "<img style=\"tv-placeholder:tv;\" src=\"\(smallCoverImage ?? "")\" width=\"250\" height=\"375\" />"
        string += "<title style=\"tv-text-highlight-style: marquee-and-show-on-highlight;\">\(title.cleaned)</title>"
        string += "</lockup>"
        return string
    }

}
