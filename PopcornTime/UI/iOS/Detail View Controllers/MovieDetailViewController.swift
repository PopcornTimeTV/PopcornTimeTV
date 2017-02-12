

import Foundation
import PopcornKit

class MovieDetailViewController: DetailViewController {
    
    var movie: Movie {
        get {
           return currentItem as! Movie
        } set(new) {
            currentItem = new
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let watchedButton = UIBarButtonItem(image: watchedButtonImage, style: .plain, target: self, action: #selector(self.toggleWatched(_:)))
        
        navigationItem.rightBarButtonItems?.insert(watchedButton, at: 0)
    }
    
    override func loadMedia(id: String, completion: @escaping (Media?, NSError?) -> Void) {
        PopcornKit.getMovieInfo(id) { (movie, error) in
            guard var movie = movie else {
                completion(nil, error)
                return
            }
            
            var error: NSError?
            let group = DispatchGroup()
                
            group.enter()
            TraktManager.shared.getRelated(movie) {
                movie.related = $0.0
                error = $0.1
                
                group.leave()
            }
            
            group.enter()
            TraktManager.shared.getPeople(forMediaOfType: .movies, id: movie.id) {
                movie.actors = $0.0
                movie.crew = $0.1
                error = $0.2
                
                group.leave()
            }
            
            group.notify(queue: .main) {
                completion(movie, error)
            }
        }
    }
    
    override var watchlistButtonImage: UIImage? {
        return WatchlistManager<Movie>.movie.isAdded(movie) ? UIImage(named: "Watchlist On") : UIImage(named: "Watchlist Off")
    }
    
    @IBAction override func toggleWatchlist(_ sender: UIBarButtonItem) {
        WatchlistManager<Movie>.movie.toggle(movie)
        sender.image = watchlistButtonImage
    }
    
    var watchedButtonImage: UIImage? {
        return WatchedlistManager<Movie>.movie.isAdded(movie.id) ? UIImage(named: "Watched On") : UIImage(named: "Watched Off")
    }
    
    func toggleWatched(_ sender: UIBarButtonItem) {
        WatchedlistManager<Movie>.movie.toggle(movie.id)
        sender.image = watchedButtonImage
    }
    
    func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    var formattedRuntime: String {
        if let runtime = Int(movie.runtime) {
            let (hours, minutes, _) = secondsToHoursMinutesSeconds(runtime * 60)
            
            let formatted = "\(hours) h"
            
            return minutes > 0 ? formatted + " \(minutes) min" : formatted
        }
        return ""
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedInfo", let vc = segue.destination as? InfoViewController {
            
            let info = NSMutableAttributedString(string: "\(movie.year)\t")
            
            attributedString(from: movie.certification, "HD", "CC").forEach({info.append($0)})
            
            vc.info = (title: movie.title, subtitle: formattedRuntime, genre: movie.genres.first?.capitalized ?? "", info: info, rating: movie.rating, summary: movie.summary, image: movie.mediumCoverImage, trailerCode: movie.trailerCode, media: movie)
            vc.delegate = self
            
            vc.view.translatesAutoresizingMaskIntoConstraints = false
        } else if let vc = segue.destination as? DescriptionCollectionViewController, segue.identifier == "embedInformation" {
            vc.headerTitle = "Information"
            
            vc.dataSource = [("Genre", movie.genres.first?.capitalized ?? "Unknown"), ("Released", movie.year), ("Run Time", formattedRuntime), ("Rating", movie.certification)]
            
            informationCollectionViewController = vc
        } else if let vc = segue.destination as? CollectionViewController {
            
            if segue.identifier == "embedRelated" {
                relatedCollectionViewController = vc
                relatedCollectionViewController.dataSources = [movie.related]
            } else if segue.identifier == "embedCast" {
                castCollectionViewController = vc
                
                let dataSource = (movie.actors as [AnyHashable]) + (movie.crew as [AnyHashable])
                castCollectionViewController.dataSources = [dataSource]
                castCollectionViewController.minItemSize.height = 230
            }
            
            super.prepare(for: segue, sender: sender)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}
