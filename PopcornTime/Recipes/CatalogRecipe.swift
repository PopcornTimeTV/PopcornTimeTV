

import TVMLKitchen
import PopcornKit

open class CatalogRecipe: RecipeType {
    fileprivate var currentPage = 1
    open var sortBy = ShowManager.Filters.date
    open var genre = ShowManager.Genres.all

    open let theme = DefaultTheme()
    open var presentationType = PresentationType.default
    var fetchType: FetchType = .movies

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

    open func lockup(didHighlightWithPage page: Int, completion: @escaping (String) -> Void) {
        if currentPage != page {
            switch fetchType {
            case .movies:
                PopcornKit.loadMovies(currentPage) { movies, error in
                    if let movies = movies {
                        let mapped = movies.map { $0.lockUp }
                        let data = mapped.joined(separator: "")
                        completion(data)
                    }
                }
            case .shows:
                PopcornKit.loadShows(currentPage, filterBy: sortBy, genre: genre, searchTerm: nil, orderBy: .descending) { shows, error in
                    if let shows = shows {
                        let mapped = shows.map { $0.lockUp }
                        let data = mapped.joined(separator: "\n")
                        completion(data)
                    }
                }
            }
            currentPage = page
        }
    }

}
