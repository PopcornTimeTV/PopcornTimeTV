

import PopcornKit

extension Movie {

    var parallaxPoster: String {
        let queryString = "title=\(title)&year=\(year)&fallback=\(mediumCoverImage)"
            .stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
            .stringByReplacingOccurrencesOfString("&", withString: "&amp;")

        return "https://lsrdb.com/search?\(queryString)"
    }

}
