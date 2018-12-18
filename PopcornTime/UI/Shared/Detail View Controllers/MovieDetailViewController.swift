

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
            TraktManager.shared.getRelated(movie) {arg1,_ in
                movie.related = arg1
                
                group.leave()
            }
            
            group.enter()
            TraktManager.shared.getPeople(forMediaOfType: .movies, id: movie.id) {arg1,arg2,_ in
                movie.actors = arg1
                movie.crew = arg2
                
                group.leave()
            }
            
            group.notify(queue: .main) {
                completion(movie, nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? DescriptionCollectionViewController, segue.identifier == "embedInformation" {
            vc.headerTitle = "Information".localized
            
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .short
            formatter.allowedUnits = [.hour, .minute]
            
            vc.dataSource = [("Genre".localized, movie.genres.first?.localizedCapitalized.localized ?? "Unknown".localized), ("Released".localized, movie.year), ("Run Time".localized, formatter.string(from: TimeInterval(movie.runtime) * 60) ?? "0 min"), ("Rating".localized, movie.certification)]
            
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
