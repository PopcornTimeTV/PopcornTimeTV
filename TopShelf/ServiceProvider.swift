

import Foundation
import TVServices
import PopcornKit

class ServiceProvider: NSObject, TVTopShelfProvider {

    override init() {
        super.init()
    }

    var topShelfStyle: TVTopShelfContentStyle {
        return .sectioned
    }

    var topShelfItems: [TVContentItem] {
        var items = [TVContentItem]()
        
        let semaphore = DispatchSemaphore(value: 0)
        let group = DispatchGroup()
        
        let completion: ([Media]?, NSError?) -> Void = { (media, error) in
            guard let media = media else { return }
            let type: String
            switch media.first! {
            case is Movie:
                type = "Movie"
            case is Show:
                type = "Show"
            default:
                type = ""
            }
            var mediaItems = [TVContentItem]()
            for item in media[0..<10] {
                mediaItems.append(
                    self.buildShelfItem(
                        item.title.cleaned,
                        image: item.mediumCoverImage,
                        action: "show\(type + "/" + item.title + "/" + item.id)"
                    )
                )
            }
            
            let latestMediaSectionTitle = "Top \(type)s"
            let latestMediaSectionItem = TVContentItem(contentIdentifier: TVContentIdentifier(identifier: latestMediaSectionTitle, container: nil)!)!
            latestMediaSectionItem.title = latestMediaSectionTitle
            latestMediaSectionItem.topShelfItems = mediaItems
            items.append(latestMediaSectionItem)
            group.leave()
        }
        group.enter()
        PopcornKit.loadMovies(filterBy: .popularity) { (movies, error) in
            completion(movies, error)
        }
        group.enter()
        PopcornKit.loadShows(filterBy: .popularity) { (shows, error) in
            completion(shows, error)
        }
        
        group.notify(queue: .main) {
            semaphore.signal()
        }
        
        semaphore.wait(timeout: .now() + 15.0)
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

