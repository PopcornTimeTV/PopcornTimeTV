

import Foundation
import TVServices
import PopcornKit
import ObjectMapper

class ServiceProvider: NSObject, TVTopShelfProvider {
    
    func toSelector(_ media: Media) -> String {
        if let movie = media as? Movie {
            return "showMovie" + "»" + (Mapper<Movie>().toJSONString(movie) ?? "")
        } else if let show = media as? Show {
            return "showShow" + "»" + (Mapper<Show>().toJSONString(show) ?? "")
        }
        return ""
    }

    var topShelfStyle: TVTopShelfContentStyle {
        return .sectioned
    }

    var topShelfItems: [TVContentItem] {
        var items = [TVContentItem]()
        
        let semaphore = DispatchSemaphore(value: 0)
        let group = DispatchGroup()
        
        let completion: ([Media]?, NSError?) -> Void = { (media, error) in
            defer { group.leave() }
            guard let media = media else { return }
            
            let type = media is [Movie] ? "Movie" : "Show"
            
            var mediaItems = [TVContentItem]()
            for item in media[0..<10] {
                mediaItems.append(
                    self.buildShelfItem(
                        item.title,
                        image: item.mediumCoverImage,
                        action: self.toSelector(item)
                    )
                )
            }
            
            let latestMediaSectionTitle = "Trending \(type)s"
            let latestMediaSectionItem = TVContentItem(contentIdentifier: TVContentIdentifier(identifier: latestMediaSectionTitle, container: nil)!)!
            latestMediaSectionItem.title = latestMediaSectionTitle
            latestMediaSectionItem.topShelfItems = mediaItems
            items.append(latestMediaSectionItem)
        }
        group.enter()
        PopcornKit.loadMovies(filterBy: .trending) { (movies, error) in
            completion(movies, error)
        }
        group.enter()
        PopcornKit.loadShows(filterBy: .trending) { (shows, error) in
            completion(shows, error)
        }
        
        group.notify(queue: .main) {
            semaphore.signal()
        }
        
        let _ = semaphore.wait(timeout: .now() + 15.0)
        return items
    }
    
    func buildShelfItem(_ title: String, image: String?, action: String) -> TVContentItem {
        let item = TVContentItem(contentIdentifier: TVContentIdentifier(identifier: title, container: nil)!)!
        if let image = image { item.imageURL = URL(string: image) }
        item.imageShape = .poster
        var components = URLComponents()
        components.scheme = "PopcornTime"
        components.queryItems = [URLQueryItem(name: "action", value: action)]
        item.displayURL = components.url
        item.playURL = components.url
        item.title = title
        return item
    }

}

