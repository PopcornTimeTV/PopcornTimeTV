

import UIKit
import PopcornKit

class ShowDetailViewController: DetailViewController {

    var show: Show {
        get {
            return currentItem as! Show
        } set(new) {
            currentItem = new
        }
    }
    
    override func loadMedia(id: String, completion: @escaping (Media?, NSError?) -> Void) {
        PopcornKit.getShowInfo(id) { (show, error) in
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard var show = show, let season = show.latestUnwatchedEpisode()?.season ?? show.seasonNumbers.first else {
                let error = NSError(domain: "com.popcorntimetv.popcorntime.error", code: -243, userInfo: [NSLocalizedDescriptionKey: "There are no seasons available for the selected show. Please try again later"])
                completion(nil, error)
                return
            }
            
            self.currentSeason = season
            
            let group = DispatchGroup()
            
            group.enter()
            TraktManager.shared.getRelated(show) {
                show.related = $0.0
                
                group.leave()
            }
            
            group.enter()
            TraktManager.shared.getPeople(forMediaOfType: .shows, id: show.id) {
                show.actors = $0.0
                show.crew = $0.1
                
                group.leave()
            }
            
            group.enter()
            self.loadEpisodeMetadata(for: show) { episodes in
                show.episodes = episodes
                group.leave()
            }
            
            group.notify(queue: .main) {
                completion(show, nil)
            }
        }
    }
    
    override func chooseQuality(_ sender: Any?, media: Media) {
        guard media.id == show.id, let episode = show.latestUnwatchedEpisode() else { return super.chooseQuality(sender, media: media) }
        
        super.chooseQuality(sender, media: episode)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedEpisodes" {
            super.prepare(for: segue, sender: sender)
            change(to: currentSeason)
        } else if let vc = segue.destination as? DescriptionCollectionViewController, segue.identifier == "embedInformation" {
            vc.headerTitle = "Information"
            
            vc.dataSource = [("Genre", show.genres.first?.capitalized ?? "Unknown"), ("Released", show.year), ("Run Time", "\(show.runtime ?? 0) min"), ("Network", show.network ?? "TV")]
            
            informationDescriptionCollectionViewController = vc
        } else if let vc = segue.destination as? CollectionViewController {
            
            if segue.identifier == "embedRelated" {
                relatedCollectionViewController = vc
                relatedCollectionViewController.dataSources = [show.related]
            } else if segue.identifier == "embedPeople" {
                peopleCollectionViewController = vc
                
                let dataSource = (show.actors as [AnyHashable]) + (show.crew as [AnyHashable])
                peopleCollectionViewController.dataSources = [dataSource]
            }
            
            super.prepare(for: segue, sender: sender)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    func loadEpisodeMetadata(for show: Show, completion: @escaping ([Episode]) -> Void) {
        let group = DispatchGroup()
        
        var episodes = [Episode]()
        
        for var episode in show.episodes {
            group.enter()
            TMDBManager.shared.getEpisodeScreenshots(forShowWithImdbId: show.id, orTMDBId: show.tmdbId, season: episode.season, episode: episode.episode, completion: { (tmdbId, image, error) in
                if let image = image { episode.largeBackgroundImage = image }
                if let tmdbId = tmdbId { episode.show.tmdbId = tmdbId }
                episodes.append(episode)
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            episodes.sort(by: { $0.episode < $1.episode })
            completion(episodes)
        }
    }

    
    func change(to season: Int) {
        seasonsLabel.text = "Season \(season)"
        currentSeason = season
        episodesCollectionViewController.dataSource = show.episodes.filter({$0.season == season}).sorted(by: {$0.0.episode < $0.1.episode})
        episodesCollectionViewController.collectionView?.reloadData()
    }
}
