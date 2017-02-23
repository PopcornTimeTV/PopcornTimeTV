

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
    
    var watchedButtonImage: UIImage? {
        return movie.isWatched ? UIImage(named: "Watched On") : UIImage(named: "Watched Off")
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
        
        #if os(iOS)
            if segue.identifier == "embedInfo", let vc = segue.destination as? InfoViewController {
                
                let info = NSMutableAttributedString(string: "\(movie.year)\t")
                
                attributedString(from: movie.certification, "HD", "CC").forEach({info.append($0)})
                
                vc.info = (title: movie.title, subtitle: formattedRuntime, genre: movie.genres.first?.capitalized ?? "", info: info, rating: movie.rating, summary: movie.summary, image: movie.mediumCoverImage, trailerCode: movie.trailerCode, media: movie)
                vc.delegate = self
                
                vc.view.translatesAutoresizingMaskIntoConstraints = false
            }
        #endif
        
        if let vc = segue.destination as? DescriptionCollectionViewController, segue.identifier == "embedInformation" {
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
            }
            
            super.prepare(for: segue, sender: sender)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}
