

import PopcornKit

extension Show {
    
    /**
     Fetch the latest unwatched episode for the current show.
     
     - Parameter episodes:  Optionally pass in a specific subset of the shows episodes. Otherwise `episodes` array on this object will be used.
     
     - Returns: Latest unwatched, or currently watching, episode, if any.
     */
    func latestUnwatchedEpisode(from episodes: [Episode]? = nil) -> Episode? {
        let episodes = episodes ?? self.episodes
        guard episodes.filter({$0.show == self}).count == episodes.count else { return nil } // Make sure all of the episodes are of the current show.
        
        let manager = WatchedlistManager<Episode>.episode
        
        let currentlyWatchingEpisodes = episodes.filter({(manager.currentProgress($0.id) > 0.0) || (manager.isAdded($0.id))}) // Fetch the latest watched/currently watching episodes.
        var latestCurrentlyWatchingEpisodesBySeason: [Episode] = []
        
        for season in seasonNumbers {
            guard let last = currentlyWatchingEpisodes.filter({$0.season == season}).sorted(by: {$0.0.episode < $0.1.episode}).last else { continue }
            latestCurrentlyWatchingEpisodesBySeason.append(last)
        }
        
        let latest = latestCurrentlyWatchingEpisodesBySeason.sorted(by: {$0.0.season < $0.1.season}).last
        
        if let episode = latest, manager.isAdded(episode.id) // If the latest currently watching episode has already been watched, return the next episode available.
        {
            if let next = episodes.filter({episode.season == $0.season}).filter({$0.episode == (episode.episode + 1)}).first {
                return next
            } else if let next = episodes.filter({$0.season == (episode.season + 1)}).sorted(by: {$0.0.episode < $0.1.episode}).first // If there are no more greater episodes in the season, return the first episode in the next season.
            {
                return next
            }
        }
        
        return latest
    }
}
