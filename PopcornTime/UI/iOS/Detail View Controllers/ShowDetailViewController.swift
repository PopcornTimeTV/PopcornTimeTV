

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        moreSeasonsButton.isHidden = show.seasonNumbers.count == 1
    }
    
    override func loadMedia(id: String, completion: @escaping (Media?, NSError?) -> Void) {
        PopcornKit.getShowInfo(id) { (show, error) in
            guard var show = show, let season = show.seasonNumbers.first else {
                completion(nil, error)
                return
            }
            
            self.currentSeason = season
            
            var error: NSError?
            let group = DispatchGroup()
            
            group.enter()
            TraktManager.shared.getRelated(show) {
                show.related = $0.0
                error = $0.1
                
                group.leave()
            }
            
            group.enter()
            TraktManager.shared.getPeople(forMediaOfType: .shows, id: show.id) {
                show.actors = $0.0
                show.crew = $0.1
                error = $0.2
                
                group.leave()
            }
            
            group.enter()
            self.loadEpisodeMetadata(for: show) { episodes in
                show.episodes = episodes
                group.leave()
            }
            
            group.notify(queue: .main) {
                completion(show, error)
            }
        }
    }
    
    @IBAction override func changeSeason(_ sender: UIButton) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet, blurStyle: .dark)
        
        let handler: (UIAlertAction) -> Void = { [unowned self] action in
            guard let title = action.title,
                let string = title.components(separatedBy: "Season ").last, let season = Int(string) else { return }
            self.change(to: season)
        }
        
        show.seasonNumbers.forEach({
            controller.addAction(UIAlertAction(title: "Season \($0)", style: .default, handler: handler))
        })
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller.preferredAction = controller.actions.first(where: {$0.title == "Season \(self.currentSeason)"})
        controller.popoverPresentationController?.sourceView = sender
        
        present(controller, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedEpisodes" {
            super.prepare(for: segue, sender: sender)
            change(to: currentSeason)
        } else if segue.identifier == "embedInfo", let vc = segue.destination as? InfoViewController {
            
            let info = NSMutableAttributedString(string: "\(show.year)\t")
            
            attributedString(from: "HD", "CC").forEach({info.append($0)})
            
            vc.info = (title: show.title, subtitle: show.network ?? "TV", genre: show.genres.first?.capitalized ?? "", info: info, rating: show.rating, summary: show.summary, image: show.mediumCoverImage, trailerCode: nil)
            vc.delegate = self
            
            vc.view.translatesAutoresizingMaskIntoConstraints = false
        } else if let vc = segue.destination as? DescriptionCollectionViewController, segue.identifier == "embedInformation" {
            vc.headerTitle = "Information"
            
            vc.dataSource = [("Genre", show.genres.first?.capitalized ?? "Unknown"), ("Released", show.year), ("Run Time", (show.runtime ?? "0") + " min"), ("Network", show.network ?? "TV")]
            
            informationCollectionViewController = vc
        } else if let vc = segue.destination as? CollectionViewController {
            
            if segue.identifier == "embedRelated" {
                relatedCollectionViewController = vc
                relatedCollectionViewController.dataSource = show.related
            } else if segue.identifier == "embedCast" {
                castCollectionViewController = vc
                
                let dataSource = (show.actors as [AnyHashable]) + (show.crew as [AnyHashable])
                castCollectionViewController.dataSource = dataSource
                castCollectionViewController.minItemSize.height = 230
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
