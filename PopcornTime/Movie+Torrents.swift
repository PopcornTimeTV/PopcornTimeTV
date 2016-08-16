

import PopcornKit

extension Movie {

    var torrentsText: String {
        let filteredTorrents: [String] = torrents.map { torrent in
            return "quality=\(torrent.quality)&hash=\(torrent.hash)"
        }
        return filteredTorrents.joinWithSeparator("•")
    }
}
