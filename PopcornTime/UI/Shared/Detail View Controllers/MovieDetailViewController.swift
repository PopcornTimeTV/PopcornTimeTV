

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
            let group = DispatchGroup()
                
            group.enter()
            TraktManager.shared.getRelated(movie) {
                movie.related = $0.0
                
                group.leave()
            }
            
            group.enter()
            TraktManager.shared.getPeople(forMediaOfType: .movies, id: movie.id) {
                movie.actors = $0.0
                movie.crew = $0.1
                
                group.leave()
            }
            
            group.notify(queue: .main) {
                completion(movie, nil)
            }
        }
    }
    
    var watchedButtonImage: UIImage? {
        return movie.isWatched ? UIImage(named: "Watched On") : UIImage(named: "Watched Off")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? DescriptionCollectionViewController, segue.identifier == "embedInformation" {
            vc.headerTitle = "Information"
            
            vc.dataSource = [("Genre", movie.genres.first?.capitalized ?? "Unknown"), ("Released", movie.year), ("Run Time", movie.formattedRuntime), ("Rating", movie.certification)]
            
            informationDescriptionCollectionViewController = vc
        } else if let vc = segue.destination as? CollectionViewController {
            
            if segue.identifier == "embedRelated" {
                relatedCollectionViewController = vc
                relatedCollectionViewController.dataSources = [movie.related]
            } else if segue.identifier == "embedPeople" {
                peopleCollectionViewController = vc
                
                let dataSource = (movie.actors as [AnyHashable]) + (movie.crew as [AnyHashable])
                peopleCollectionViewController.dataSources = [dataSource]
            }
            
            super.prepare(for: segue, sender: sender)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}
