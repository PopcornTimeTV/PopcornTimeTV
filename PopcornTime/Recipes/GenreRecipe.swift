

import TVMLKitchen
import PopcornKit

public struct GenreRecipe: RecipeType {

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.Tab
    var fetchType: FetchType! = .Movies
    let movieGenres = ["Action", "Adventure", "Animation", "Biography",
                       "Comedy", "Crime", "Documentary", "Drama", "Family",
                       "Fantasy", "History", "Horror", "Music",
                       "Musical", "Mystery", "Romance", "Sport", "Thriller",
                       "War", "Western"]
    let tvGenres = [ "Action", "Adventure", "Animation", "Children", "Comedy",
                     "Crime", "Documentary", "Drama", "Family", "Fantasy",
                     "History", "Horror", "Mystery", "News", "Reality", "Romance"]

    init(fetchType: FetchType = .Movies) {
        self.fetchType = fetchType
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }

    public var listItems: String {
        switch fetchType! {
        case .Movies:
            let mappedListItem: [String] = movieGenres.map {
                let listItem = "<listItemLockup actionID=\"showGenre»\($0)»movie\" sectionID=\"\($0)\"> \n" +
                             "<title>\($0)</title> \n" +
                             "<relatedContent> \n" +
                             "<imgDeck id=\"\($0)\"></imgDeck> \n" +
                             "</relatedContent> \n" +
                             "</listItemLockup>"
                return listItem
            }
            return mappedListItem.joinWithSeparator("\n")
        case .Shows:
            let mappedListItem: [String] = tvGenres.map {
                let listItem = "<listItemLockup actionID=\"showGenre»\($0)»show\" sectionID=\"\($0)\"> \n" +
                    "<title>\($0)</title> \n" +
                    "<relatedContent> \n" +
                    "<imgDeck id=\"\($0)\"></imgDeck> \n" +
                    "</relatedContent> \n" +
                "</listItemLockup>"
                return listItem
            }
            return mappedListItem.joinWithSeparator("\n")
        }
    }

    public var template: String {
        var xml = ""
        if let file = NSBundle.mainBundle().URLForResource("GenreRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOfURL: file)
                xml = xml.stringByReplacingOccurrencesOfString("{{LIST_ITEMS}}", withString: listItems)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }

    public func highlightSection(text: String, callback: (String -> Void)) {
        var data = ""
        let semaphore = dispatch_semaphore_create(0)
        switch self.fetchType! {
            case .Movies:
            NetworkManager.sharedManager().fetchMovies(limit: 50, page: 1, quality: "720p", minimumRating: 0, queryTerm: nil, genre: text, sortBy: "download_count", orderBy: "desc") { movies, error in
                if let movies = movies {
                    let mapped: [String] = movies.map { movie in
                        movie.lockUpGenre
                    }
                    data = mapped.joinWithSeparator("\n")
                    dispatch_semaphore_signal(semaphore)
                }
            }
            case .Shows:
            let manager = NetworkManager.sharedManager()
            manager.fetchShowPageNumbers { pageNumbers, error in
                if let pageNumbers = pageNumbers {
                    manager.fetchShows(pageNumbers, searchTerm: nil, genre: text, sort: "trending", order: "1") { shows, error in
                        if let shows = shows {
                            let mapped: [String] = shows.map { show in
                                show.lockUpGenre
                            }
                            data = mapped.joinWithSeparator("\n")
                            dispatch_semaphore_signal(semaphore)
                        }
                    }
                }
            }

        }

        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        callback(data)
    }

}
