

import Foundation
import TVServices
import PopcornKit

class ServiceProvider: NSObject, TVTopShelfProvider {
    
    var items = [TVContentItem]()
    
    override init() {
        super.init()
    }

    // MARK: - TVTopShelfProvider protocol

    var topShelfStyle: TVTopShelfContentStyle {
        // Return desired Top Shelf style.
        return .sectioned
    }

    var topShelfItems: [TVContentItem] {
        self.items.removeAll()
        
        let semaphore = DispatchSemaphore(value: 0)
        
        manager.fetchServers { servers, error in
            if let servers = servers {
                if let yts = servers["yts"] as? [String],
                   let eztv = servers["eztv"] as? [String],
                   let kat = servers["kat"] as? [String] {
                    self.manager.setServerEndpoints(yts: yts.first!, eztv: eztv.first!, kat: kat.first!)
                    self.manager.fetchShowsForPage(1) { shows, error in
                        if let shows = shows {
                            self.manager.fetchMovies(limit: 10, page: 1, quality: "1080p", minimumRating: 3, queryTerm: nil, genre: nil, sortBy: "seeds", orderBy: "desc", withImages: true) { movies, error in
                                if let movies = movies {
                                    
                                    // Movies
                                    var movieItems = [TVContentItem]()
                                    for movie in movies {
                                        movieItems.append(
                                            self.buildShelfItem(
                                                movie.title.cleaned,
                                                image: movie.mediumCoverImage,
                                                action: "showMovie/\(String(movie.id))"
                                            )
                                        )
                                    }
                                    
                                    let latestMoviesSectionTitle = "Top Movies"
                                    let latestMovieSectionItem = TVContentItem(contentIdentifier: TVContentIdentifier(identifier: latestMoviesSectionTitle, container: nil)!)
                                    latestMovieSectionItem!.title = latestMoviesSectionTitle
                                    latestMovieSectionItem!.topShelfItems = movieItems
                                    
                                    self.items.append(latestMovieSectionItem!)
                                    
                                }
                                
                                // Shows
                                var showItems = [TVContentItem]()
                                for show in shows[0..<10] {
                                    showItems.append(
                                        self.buildShelfItem(
                                            show.title.cleaned,
                                            image: show.posterImage,
                                            action: "showShow/\(show.id)/\(show.title.slugged)/\(show.tvdbId)"
                                        )
                                    )
                                }
                              
                                let popularShowsSectionTitle = "Top Shows"
                                let popularShowSectionItem = TVContentItem(contentIdentifier: TVContentIdentifier(identifier: popularShowsSectionTitle, container: nil)!)
                                popularShowSectionItem!.title = popularShowsSectionTitle
                                popularShowSectionItem!.topShelfItems = showItems
                                
                                self.items.append(popularShowSectionItem!)
                                
                                dispatch_semaphore_signal(semaphore)
                            }
                        }
                    }
                }
            }
        }
        
        semaphore.wait(timeout: DispatchTime.distantFuture)
        return self.items
    }
    
    func buildShelfItem(_ title: String, image: String, action: String) -> TVContentItem {
        let item = TVContentItem(contentIdentifier: TVContentIdentifier(identifier: title, container: nil)!)
        item!.imageURL = URL(string: image)
        item!.imageShape = .poster
        item!.displayURL = URL(string: "PopcornTimeTV://\(action)")
        item!.playURL = URL(string: "PopcornTimeTV://\(action)")
        item!.title = title
        return item!
    }

}

