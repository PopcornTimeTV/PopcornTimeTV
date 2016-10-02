

import PopcornKit

extension Movie {

    var parallaxPoster: String {
        let queryString = "title=\(title)&year=\(year)&fallback=\(mediumCoverImage)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)?.replacingOccurrences(of: "&", with: "&amp;")
        return "https://lsrdb.com/search?\(queryString)"
    }

}
