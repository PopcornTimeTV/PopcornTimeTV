

import TVMLKitchen
import PopcornKit

public class CatalogRecipe: RecipeType {
    private var currentPage = 1
    public var minimumRating = 0
    public var sortBy = "date_added"
    public var genre = ""

    public let theme = DefaultTheme()
    public var presentationType = PresentationType.Tab
    var fetchType: FetchType! = .Movies

    let title: String
    let movies: [Movie]!
    let shows: [Show]!

    init(title: String, movies: [Movie]? = nil, shows: [Show]? = nil) {
        self.title = title
        self.movies = movies
        self.shows = shows
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    public var creditsString: String {
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

            mapped.sortInPlace {
                return $0[1] > $1[1]
            }

            let mappedItems: [String] = mapped.map {
                $0[0]
            }

            return mappedItems.joinWithSeparator("")
    }

    public var template: String {
        var xml = ""
        if let file = NSBundle.mainBundle().URLForResource("CatalogRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOfURL: file)
                xml = xml.stringByReplacingOccurrencesOfString("{{TITLE}}", withString: title)
                xml = xml.stringByReplacingOccurrencesOfString("{{POSTERS}}", withString: creditsString)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

    public func highlightLockup(page: Int, callback: (String -> Void)) {
        var data = ""
        let semaphore = dispatch_semaphore_create(0)
        if self.currentPage != page {
            switch self.fetchType! {
            case .Movies:
                NetworkManager.sharedManager().fetchMovies(limit: 50, page: page, quality: "1080p", minimumRating: self.minimumRating, queryTerm: nil, genre: self.genre, sortBy: self.sortBy, orderBy: "desc") { movies, error in
                    if let movies = movies {
                        let mapped: [String] = movies.map { movie in
                            movie.lockUp
                        }
                        data = mapped.joinWithSeparator("")
                        dispatch_semaphore_signal(semaphore)
                    }
                }
            case .Shows:
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

        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        callback(data)
    }

}
