

import TVMLKitchen
import PopcornKit

open class CatalogRecipe: RecipeType {
    fileprivate var currentPage = 1
    open var minimumRating = 0
    open var sortBy = "date_added"
    open var genre = ""

    open let theme = DefaultTheme()
    open var presentationType = PresentationType.Default
    var fetchType: FetchType! = .movies

    let title: String
    let movies: [Movie]!
    let shows: [Show]!

    init(title: String, movies: [Movie]? = nil, shows: [Show]? = nil) {
        self.title = title
        self.movies = movies
        self.shows = shows
    }

    open var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    open var creditsString: String {
            var mapped = [[String]]()

            if movies != nil {
                mapped += movies.map {
                    [$0.lockUp, String($0.year)]
                }
            }
            if shows != nil {
                mapped += shows.map {
                    [$0.lockUp, String($0.year)]
                }
            }

            mapped.sort {
                return $0[1] > $1[1]
            }

            let mappedItems: [String] = mapped.map {
                $0[0]
            }

            return mappedItems.joined(separator: "")
    }

    open var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "CatalogRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)
                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: title)
                xml = xml.replacingOccurrences(of: "{{POSTERS}}", with: creditsString)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

    open func highlightLockup(_ page: Int, callback: ((String) -> Void)) {
        var data = ""
        let semaphore = DispatchSemaphore(value: 0)
        if self.currentPage != page {
            switch self.fetchType! {
            case .movies:
                NetworkManager.sharedManager().fetchMovies(limit: 50, page: page, quality: "1080p", minimumRating: self.minimumRating, queryTerm: nil, genre: self.genre, sortBy: self.sortBy, orderBy: "desc") { movies, error in
                    if let movies = movies {
                        let mapped: [String] = movies.map { movie in
                            movie.lockUp
                        }
                        data = mapped.joinWithSeparator("")
                        dispatch_semaphore_signal(semaphore)
                    }
                }
            case .shows:
                let manager = NetworkManager.sharedManager()
                manager.fetchShowPageNumbers { pageNumbers, error in
                    if let _ = pageNumbers {
                        // this is temporary limit until solve pagination
                        manager.fetchShows([page], sort: self.sortBy, genre: self.genre) { shows, error in
                            if let shows = shows {
                                let mapped: [String] = shows.map { show in
                                    show.lockUp
                                }
                                data = mapped.joinWithSeparator("\n")
                                dispatch_semaphore_signal(semaphore)
                            }
                        }
                    }
                }
            }
            self.currentPage = page
        }

        semaphore.wait(timeout: DispatchTime.distantFuture)
        callback(data)
    }

}
