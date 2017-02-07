

import TVMLKitchen
import PopcornKit
import PopcornTorrent
import AVKit
import XCDYouTubeKit
import ObjectMapper
import AlamofireImage
import SwiftKVC

/**
 Handles all the navigation throughout the app. A string containing a method name and two optional parameters are passed into the `primary:` method. This in turn, generates the method from the string and executes it. Every method in this file has no public parameter names. This is for ease of use when calculating their names using perform selector.
 */
class ActionHandler: NSObject, PCTPlayerViewControllerDelegate {
    
    /// Singleton instance of ActionHandler class.
    static let shared = ActionHandler()
    
    /// Active product recipe.
    var productRecipe: ProductRecipe?
    
    /// Active product recipe.
    var searchRecipe: SearchRecipe?
    
    /// Active media tab bar recipe.
    var mediaRecipe: MediaRecipe?
    
    /// The active tabBarController.
    var tabBar: KitchenTabBar!
    
    /// The active cookbook for the application.
    var cookbook: Cookbook!
    
    /**
     Generate a method from a function signature and parameters.
     
     - Parameter named:         The valid name of a method inside the `ActionHandler` class.
     - Parameter parameters:    If the method has parameters, pass them in. 
     
     - Important: No more than 2 parameters may be passed in or application will crash.
     */
    private func performSelector(named methodSignature: String, parameters: [String]) {
        assert(parameters.count <= 2, "performSelector will not work with more than two function arguments.")

        switch parameters.count {
        case 0:
            let selector = Selector(methodSignature)
            perform(selector)
        case 1:
            let selector = Selector(methodSignature + ":")
            perform(selector, with: parameters[0])
        case 2:
            let selector = Selector(methodSignature + "::")
            perform(selector, with: parameters[0], with: parameters[1])
        default:
            return
        }
    }

    /**
     The action handler for when the primary (select) button is pressed

     - Parameter id: The actionID of the element pressed
     */
    func primary(_ id: String) {
        var pieces = id.components(separatedBy: "»")
        performSelector(named: pieces.removeFirst(), parameters: pieces)
    }
    
    /**
     Serves the main tabBarController with view controllers attached.
     
     - Parameter completion: Not really a completion handler, just a block called 2 seconds after the function ends.
     */
    func loadTabBar(completion: (() -> Void)? = nil) {
        tabBar = KitchenTabBar(items: [Movies(), Shows(), Watchlist(), Search(), Settings()])
        Kitchen.serve(recipe: tabBar)
        
        guard let completion = completion else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: completion)
    }
    
    // MARK: Hackery
    
    /**
     Replaces tabBarController's template view controller with desired view controller loaded from `Main.storyboard`.
     
     - Parameter identifier:    The storyboard id of the viewController.
     - Parameter type:          The type of the viewController.
     - Parameter index:         The index of the viewController in relation to the tabBarController's viewController array.
     
     - Returns: The viewController instance.
    */
    func addViewController<T: UIViewController>(with identifier: String, of type: T.Type, at index: Int) -> T? {
        guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier) as? T,
            let tabBarController = Kitchen.navigationController.viewControllers.first?.templateViewController as? UITabBarController,
            var viewControllers = tabBarController.viewControllers else { return nil }
        
        OperationQueue.main.addOperation {
            // Unfortunately replacing the actual view controller is not supported and causes some weirdness with _TVMenuBarController.
            viewControllers[index].view.addSubview(viewController.view)
        }
        
        return viewController
    }
    
    /**
     Evaluates javascript in the global context and maps all local functions to their js counterparts
     
     - Parameter script:        The Javascript to be evaluated.
     - Parameter completion:    The completion handler called when the JS has finished evaluating.
     */
    func evaluate(script: String, completion: ((Bool) -> Void)? = nil) {
        
        var castingValues: [String: AnyObject] = [:]
        
        if let productRecipe = productRecipe {
            castingValues[productRecipe.media.id] = productRecipe
        }
        
        if let mediaRecipe = mediaRecipe {
            castingValues[mediaRecipe.title.lowercased()] = mediaRecipe
        }
        
        if let searchRecipe = searchRecipe {
            castingValues["search"] = searchRecipe
            
            let filterSearchTextBlock: @convention(block) (String, JSValue) -> () = { (text, callback) in
                searchRecipe.filterSearchText(text) { string in
                    callback.call(withArguments: [string])
                }
            }
            castingValues["filterSearchText"] = unsafeBitCast(filterSearchTextBlock, to: AnyObject.self)
        }
        
        Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
            castingValues.forEach({context.setObject($0.1, forKeyedSubscript: $0.0 as (NSCopying & NSObjectProtocol)!)})
            context.evaluateScript(script)
        }, completion: completion)
    }
    
    // MARK: - Watchlist
    
    /**
     Adds movie to the users watchlist if it's not added, removes if it is and optionally syncs with trakt. UI is updated here.
     
     - Parameter movieString: A JSON representation of the movie object to be added to the watchlist. Use `Mapper` to achieve this.
     */
    func toggleMovieWatchlist(_ movieString: String) {
        guard let movie = Mapper<Movie>().map(JSONString: movieString) else { return }
        WatchlistManager<Movie>.movie.toggle(movie)
        Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
            context.objectForKeyedSubscript(movie.id).invokeMethod("updateWatchlistButton", withArguments: nil)
        })
    }
    
    /**
     Adds show to the users watchlist if it's not added, removes if it is and optionally syncs with trakt. UI is updated here.
     
     - Parameter showString: A JSON representation of the show object to be added to the watchlist. Use `Mapper` to achieve this.
     */
    func toggleShowWatchlist(_ showString: String) {
        guard let show = Mapper<Show>().map(JSONString: showString) else { return }
        WatchlistManager<Show>.show.toggle(show)
        Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
            context.objectForKeyedSubscript(show.id).invokeMethod("updateWatchlistButton", withArguments: nil)
        })
    }
    
    // MARK: - Watchedlist
    
    /**
     Marks a movie as watched and adds to the users watchedlist if it's not added, removes if it is and optionally syncs with trakt. UI is updated here.
     
     - Parameter movieString: A JSON representation of the movie object to be added to the watchedlist. Use `Mapper` to achieve this.
     */
    func toggleMovieWatched(_ movieString: String) {
        guard let movie = Mapper<Movie>().map(JSONString: movieString) else { return }
        WatchedlistManager<Movie>.movie.toggle(movie.id)
        Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
            context.objectForKeyedSubscript(movie.id).invokeMethod("updateWatchedButton", withArguments: nil)
        })
    }
    
    /**
     If the description exceeds 6 lines, it becomes selectable and calls this upon selection. 
     
     - Parameter title:     The title of the media the user is viewing.
     - Parameter message:   The full description.
     */
    func showDescription(_ title: String, _ message: String) {
        Kitchen.serve(recipe: DescriptionRecipe(title: title, message: message))
    }
    
    /// Dismisses the top modally presented view controller.
    func closeAlert() {
        Kitchen.dismissModal()
    }
    
    // MARK: - Movies
    
    /**
     Presents detail movie view. Called when a user taps on a movie.
     
     - Parameter mediaString: A JSON representation of the movie object. Use `Mapper` to achieve this.
     - Parameter autoplay:    Passing in `true` will result in the movie being played as soon as the view controller has loaded.
     */

    func showMovie(_ movieString: String, _ autoplay: String) {
        guard let movie = Mapper<Movie>().map(JSONString: movieString), let autoplay = Bool(autoplay) else { return }
        Kitchen.serve(recipe: LoadingRecipe(message: movie.title))
        
        PopcornKit.getMovieInfo(movie.id) { (movie, error) in
            guard var movie = movie else {
                var viewcontrollers = Kitchen.navigationController.viewControllers
                viewcontrollers.removeLast()
                Kitchen.navigationController.setViewControllers(viewcontrollers, animated: true)
                Kitchen.serve(recipe: AlertRecipe(title: "Failed to load movie.", description: error?.code == 4 ? "No torrents available for selected movie." : error!.localizedDescription, buttons: [AlertButton(title: "Okay", actionID: "closeAlert")]))
                return
            }
            
            let group = DispatchGroup()
            var fanartLogo: String?
            
            group.enter()
            TMDBManager.shared.getLogo(forMediaOfType: .movies, id: movie.id) { (image, error) in
                fanartLogo = image
                group.leave()
            }
            
            group.enter()
            TraktManager.shared.getRelated(movie, completion: { (movies, _) in
                movie.related = movies
                group.leave()
            })
            
            group.enter()
            TraktManager.shared.getPeople(forMediaOfType: .movies, id: movie.id, completion: { (actors, crew, _) in
                movie.actors = actors
                movie.crew = crew
                group.leave()
            })
            
            group.notify(queue: .main, execute: { [unowned self] in
                guard let viewController = Kitchen.appController.navigationController.visibleViewController,
                    viewController.isLoadingViewController else { return }
                
                let recipe = MovieProductRecipe(movie: movie, fanart: fanartLogo)
                self.productRecipe = recipe
                
                let file = Bundle.main.url(forResource: "ProductRecipe", withExtension: "js")!
                var script = try! String(contentsOf: file).replacingOccurrences(of: "{{RECIPE}}", with: recipe.xmlString)
                script = script.replacingOccurrences(of: "{{RECIPE_NAME}}", with: movie.id)
                
                self.evaluate(script: script) { _ in
                    self.dismissLoading() { _ in
                        guard autoplay else { return }
                        ActionHandler.shared.chooseQuality(Mapper<Torrent>().toJSONString(movie.torrents) ?? "", Mapper<Movie>().toJSONString(movie) ?? "")
                    }
                }
            })
        }
    }
    
    /**
     Pops the second last view controller from the navigation stack 1 second after the method is called. This can be used to dismiss the loading view controller that is presented when showing movie detail or show detail.
     
     - Parameter completion: Called when the view controller has sucessfully been popped from the navigation stack. Boolean value indicates the success of the operation. Will only fail if the top view controller is not a loadingViewController.
     */
    func dismissLoading(completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            var viewControllers = Kitchen.navigationController.viewControllers
            guard let viewController = Kitchen.navigationController.viewControllers[safe: viewControllers.count - 2],
                viewController.isLoadingViewController else { completion?(false); return }
            viewControllers.remove(at: viewControllers.count - 2)
            Kitchen.navigationController.setViewControllers(viewControllers, animated: false)
            completion?(true)
        })
    }
    
    // MARK: - Shows
    
    /**
     Presents detail show view. Called when a user taps on a show.
     
     - Parameter showString:              A JSON representation of the show object. Use `Mapper` to achieve this.
     - Parameter autoplayEpisodeString:   The episode to be played as soon as the view controller is presented. Pass an empty string to disable.
     */
    func showShow(_ showString: String, _ autoplayEpisodeString: String) {
        guard let show = Mapper<Show>().map(JSONString: showString) else { return }
        
        let episode = Mapper<Episode>().map(JSONString: autoplayEpisodeString)
        
        Kitchen.serve(recipe: LoadingRecipe(message: show.title))
        
        PopcornKit.getShowInfo(show.id) { (show, error) in
            guard var show = show else {
                var viewcontrollers = Kitchen.navigationController.viewControllers
                viewcontrollers.removeLast()
                Kitchen.navigationController.setViewControllers(viewcontrollers, animated: true)
                Kitchen.serve(recipe: AlertRecipe(title: "Failed to load show.", description: error!.localizedDescription, buttons: [AlertButton(title: "Okay", actionID: "closeAlert")]))
                return
            }
            
            let group = DispatchGroup()
            var fanartLogo: String?
            
            group.enter()
            TMDBManager.shared.getLogo(forMediaOfType: .shows, id: show.tvdbId) { (image, error) in
                fanartLogo = image
                group.leave()
            }
            
            group.enter()
            TraktManager.shared.getRelated(show, completion: { (shows, _) in
                show.related = shows
                group.leave()
            })
            
            group.enter()
            TraktManager.shared.getPeople(forMediaOfType: .shows, id: show.id, completion: { (actors, crew, _) in
                show.actors = actors
                show.crew = crew
                group.leave()
            })
            
            group.enter()
            self.loadEpisodeMetadata(for: show) { episodes in
                show.episodes = episodes
                group.leave()
            }
            
            group.notify(queue: .main, execute: {
                guard let viewController = Kitchen.appController.navigationController.visibleViewController,
                    viewController.isLoadingViewController else { return }
                
                guard let recipe = ShowProductRecipe(show: show, currentSeason: episode?.season, fanart: fanartLogo) else {
                    Kitchen.appController.navigationController.popViewController(animated: true)
                    Kitchen.serve(recipe: AlertRecipe(title: "No episodes available", description: "There are no available episodes for \(show.title).", buttons: [AlertButton(title: "Okay", actionID: "closeAlert")]))
                    return
                }
                self.productRecipe = recipe
                
                let file = Bundle.main.url(forResource: "ProductRecipe", withExtension: "js")!
                var script = try! String(contentsOf: file).replacingOccurrences(of: "{{RECIPE}}", with: recipe.xmlString)
                script = script.replacingOccurrences(of: "{{RECIPE_NAME}}", with: show.id)
                
                self.evaluate(script: script) { _ in
                    self.dismissLoading() { _ in
                        /// Just in case popcorn time doesn't have passed in episode or it doesn't have torrents associated with it.
                        guard let episode = show.episodes.first(where: {$0 == episode}) else { return }
                        ActionHandler.shared.chooseQuality(Mapper<Torrent>().toJSONString(episode.torrents) ?? "", Mapper<Episode>().toJSONString(episode) ?? "")
                    }
                }
            })
        }
    }
    
    /**
     Presents UI for user to choose a season to watch.
     
     Parameter showString: A JSON representation of the show object to be updated. Use `Mapper` to achieve this.
     Parameter episodesString: A JSON representation of the episode objects that metadata is to be fetched about. Use `Mapper` to achieve this.
     */
    func showSeasons(_ showString: String, _ episodesString: String) {
        guard var show = Mapper<Show>().map(JSONString: showString), let episodes = Mapper<Episode>().mapArray(JSONString: episodesString) else { return }
        show.episodes = episodes
        
        let group = DispatchGroup()
        var images = [String](repeating: "", count: show.seasonNumbers.count)
        for (index, season) in show.seasonNumbers.enumerated() {
            group.enter()
            TMDBManager.shared.getSeasonPoster(ofShowWithImdbId: show.id, orTMDBId: show.tmdbId, season: season, completion: { (tmdb, image, error) in
                if let tmdb = tmdb { show.tmdbId = tmdb }
                images[index] = image ?? show.largeCoverImage ?? ""
                group.leave()
            })
        }
        
        group.notify(queue: .main, execute: {
            let recipe = SeasonPickerRecipe(show: show, seasonImages: images)
            Kitchen.serve(recipe: recipe)
        })
    }
    
    /**
     Updates show detail UI with selected season information.
     
     - Parameter number: String representation of the season to load.
     */
    func showSeason(_ number: String) {
        guard let shelf = productRecipe?.doc?.invokeMethod("getElementById", withArguments: ["episodeShelf"]),
            let subtitle = productRecipe?.doc?.invokeMethod("getElementById", withArguments: ["seasonSubtitle"]),
            let recipe = productRecipe as? ShowProductRecipe else { return }
        recipe.season = Int(number)!
        subtitle.setObject(recipe.seasonString, forKeyedSubscript: "innerHTML" as (NSCopying & NSObjectProtocol)!)
        shelf.setObject(recipe.episodeShelf, forKeyedSubscript: "innerHTML" as (NSCopying & NSObjectProtocol)!)
        Kitchen.dismissModal()
    }
    
    /**
     Load episode images from trakt.
     
     - Parameter show:          The show that episode metadata is to be requested.
     - Parameter completion:    Completion handler containing the updated episodes.
     */
    func loadEpisodeMetadata(for show: Show, completion: @escaping ([Episode]) -> Void) {
        let group = DispatchGroup()
        
        var episodes = [Episode]()
        
        for var episode in show.episodes {
            group.enter()
            TMDBManager.shared.getEpisodeScreenshots(forShowWithImdbId: show.id, orTMDBId: show.tmdbId, season: episode.season, episode: episode.episode, completion: { (tmdbId, image, error) in
                if let image = image { episode.largeBackgroundImage = image }
                if let tmdbId = tmdbId { episode.show.tmdbId = tmdbId }
                episodes.append(episode)
                group.leave()
            })
        }
        
        group.notify(queue: .main, execute: {
            episodes.sort(by: { $0.episode < $1.episode })
            completion(episodes)
        })
    }
    
    // MARK: - Genres
    
    /**
     Present an alert of movie genres for user to pick from.
     
     - Parameter currentGenre: The genre already selected.
     */
    func showMovieGenres(_ currentGenre: String) {
        guard let genre = MovieManager.Genres(rawValue: currentGenre) else { return }
        
        let controller = UIAlertController(title: "Select a genre to filter by", message: nil, preferredStyle: .actionSheet)
        
        let handler: ((UIAlertAction) -> Void) = { (handler) in
            ActionHandler.shared.genreWasPicked(handler.title!)
        }
        
        MovieManager.Genres.array.forEach {
            controller.addAction(UIAlertAction(title: $0.rawValue, style: .default, handler: handler))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller.preferredAction = controller.actions.first(where: {$0.title == genre.rawValue})
        
        OperationQueue.main.addOperation {
             Kitchen.appController.navigationController.present(controller, animated: true, completion: nil)
        }
    }
    
    /**
     Present an alert of show genres for user to pick from.
     
     - Parameter currentGenre: The genre already selected.
     */
    func showShowGenres(_ currentGenre: String) {
        guard let genre = ShowManager.Genres(rawValue: currentGenre) else { return }
        
        let controller = UIAlertController(title: "Select a genre to filter by", message: nil, preferredStyle: .actionSheet)
        
        let handler: ((UIAlertAction) -> Void) = { (handler) in
            ActionHandler.shared.genreWasPicked(handler.title!)
        }
        
        ShowManager.Genres.array.forEach {
            controller.addAction(UIAlertAction(title: $0.rawValue, style: .default, handler: handler))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller.preferredAction = controller.actions.first(where: {$0.title == genre.rawValue})
        
        OperationQueue.main.addOperation {
            Kitchen.appController.navigationController.present(controller, animated: true, completion: nil)
        }
    }
    
    /**
     Called when a genre was picked from alert. Triggers a UI update to filter content by new genre.
     
     - Parameter genre: The genre that was picked.
     */
    func genreWasPicked(_ genre: String) {
        guard let mediaRecipe = mediaRecipe, let element = mediaRecipe.collectionList else { return }
        
        mediaRecipe.genreWasPicked(genre) { data in
            Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
                context.objectForKeyedSubscript("refresh").call(withArguments: [element, data, mediaRecipe.doc!])
                context.objectForKeyedSubscript("addEventListeners").call(withArguments: [mediaRecipe])
            })
        }
    }
    
    // MARK: Filters
    
    /**
     Present an alert of show filters for user to pick from.
     
     - Parameter currentFilter: The filter already selected.
     */
    func showShowFilters(_ currentFilter: String) {
        guard let filter = ShowManager.Filters(rawValue: currentFilter) else { return }
        
        let controller = UIAlertController(title: "Select a filter to sort by", message: nil, preferredStyle: .actionSheet)
        
        let handler: ((UIAlertAction) -> Void) = { (handler) in
            ActionHandler.shared.filterWasPicked(ShowManager.Filters.array.first(where: {$0.string == handler.title!})!.rawValue)
        }
        
        ShowManager.Filters.array.forEach {
            controller.addAction(UIAlertAction(title: $0.string, style: .default, handler: handler))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller.preferredAction = controller.actions.first(where: {$0.title == filter.string})
        
        OperationQueue.main.addOperation {
             Kitchen.appController.navigationController.present(controller, animated: true, completion: nil)
        }
    }
    
    /**
     Present an alert of movie filters for user to pick from.
     
     - Parameter currentFilter: The filter already selected.
     */
    func showMovieFilters(_ currentFilter: String) {
        guard let filter = MovieManager.Filters(rawValue: currentFilter) else { return }
        
        let controller = UIAlertController(title: "Select a filter to sort by", message: nil, preferredStyle: .actionSheet)
        
        let handler: ((UIAlertAction) -> Void) = { (handler) in
            ActionHandler.shared.filterWasPicked(MovieManager.Filters.array.first(where: {$0.string == handler.title!})!.rawValue)
        }
        
        MovieManager.Filters.array.forEach {
            controller.addAction(UIAlertAction(title: $0.string, style: .default, handler: handler))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller.preferredAction = controller.actions.first(where: {$0.title == filter.string})
        
        OperationQueue.main.addOperation {
             Kitchen.appController.navigationController.present(controller, animated: true, completion: nil)
        }
    }
    
    /**
     Called when a filter was picked from alert. Triggers a UI update to sort content by new filter.
     
     - Parameter filter: The filter that was picked.
     */
    func filterWasPicked(_ filter: String) {
        guard let mediaRecipe = mediaRecipe, let element = mediaRecipe.collectionList else { return }
        
        mediaRecipe.filterWasPicked(filter) { data in
            Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
                context.objectForKeyedSubscript("refresh").call(withArguments: [element, data, mediaRecipe.doc!])
                context.objectForKeyedSubscript("addEventListeners").call(withArguments: [mediaRecipe])
            })
        }
        
    }

    
    // MARK: - Credits
    
    /**
     Present a catalog of movies that an actor starred in or was working in.
     
     - Parameter name:  Name of person.
     - Parameter id:    ImdbId of person.
     */
    func showMovieCredits(_ name: String, _ id: String) {
        Kitchen.serve(recipe: LoadingRecipe(message: name))
        
        TraktManager.shared.getMediaCredits(forPersonWithId: id, mediaType: Movie.self) { (movies, error) in
            if let error = error {
                let backgroundView = ErrorBackgroundView()
                backgroundView.setUpView(error: error)
                Kitchen.serve(xmlString: backgroundView.xmlString, type: .default)
                return
            }
            
            let movies = movies.unique().map({$0.lockUp}).joined(separator: "\n")
            let recipe = CatalogRecipe(title: name, media: movies)
            Kitchen.serve(recipe: recipe)
            self.dismissLoading()
        }
    }
    
    /**
     Present a catalog of shows that an actor starred in or was working in.
     
     - Parameter name:  Name of person.
     - Parameter id:    ImdbId of person.
     */
    func showShowCredits(_ name: String, _ id: String) {
        Kitchen.serve(recipe: LoadingRecipe(message: name))
        
        TraktManager.shared.getMediaCredits(forPersonWithId: id, mediaType: Show.self) { (shows, error) in
            if let error = error {
                let backgroundView = ErrorBackgroundView()
                backgroundView.setUpView(error: error)
                Kitchen.serve(xmlString: backgroundView.xmlString, type: .default)
                return
            }
            let shows = shows.unique().map({$0.lockUp}).joined(separator: "\n")
            let recipe = CatalogRecipe(title: name, media: shows)
            Kitchen.serve(recipe: recipe)
            self.dismissLoading()
        }
    }
    
    /**
     Present a catalog of movies and shows that an actor starred in or was working in.
     
     - Parameter name:  Name of person.
     - Parameter id:    ImdbId of person.
     */
    func showCredits(_ name: String, _ id: String) {
        Kitchen.serve(recipe: LoadingRecipe(message: name))
        
        let group = DispatchGroup()
        var lockup = ""
        var error: NSError?
        
        group.enter()
        TraktManager.shared.getMediaCredits(forPersonWithId: id, mediaType: Show.self) {
            defer { group.leave() }
            guard $0.1 == nil else {
                error = $0.1
                return
            }
            let shows = $0.0.unique().map({$0.lockUp}).joined(separator: "\n")
            lockup += shows
        }
        
        group.enter()
        TraktManager.shared.getMediaCredits(forPersonWithId: id, mediaType: Movie.self) {
            defer { group.leave() }
            guard $0.1 == nil else {
                error = $0.1
                return
            }
            let movies = $0.0.unique().map({$0.lockUp}).joined(separator: "\n")
            lockup += movies
        }
        
        group.notify(queue: .main) { 
            guard !lockup.isEmpty && error == nil else {
                let backgroundView = ErrorBackgroundView()
                let error = error ?? NSError(domain: "com.popcorntimetv.popcorntime.tvos.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No media found"])
                backgroundView.setUpView(error: error)
                Kitchen.serve(xmlString: backgroundView.xmlString, type: .default)
                return
            }
            
            let recipe = CatalogRecipe(title: name, media: lockup)
            Kitchen.serve(recipe: recipe)
            self.dismissLoading()
        }
    }
    
    // MARK: - Media
    
    /**
     Begin streaming a movie. This method will handle presenting the loading view controller as well as the playing view controller.
     
     - Parameter torrentString: A JSON representation of the torrent object to be streamed. Use `Mapper` to achieve this.
     - Parameter mediaString:   A JSON representation of the movie or show object to be streamed. Use `Mapper` to achieve this.
     */
    func streamTorrent(_ torrentString: String, _ mediaString: String) {
        guard var media: Media = Mapper<Movie>().map(JSONString: mediaString) ?? Mapper<Episode>().map(JSONString: mediaString), let torrent = Mapper<Torrent>().map(JSONString: torrentString) else { return }
        
        Kitchen.dismissModal()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let present: (UIViewController, Bool) -> Void = { (viewController, animated) in
            OperationQueue.main.addOperation {
                Kitchen.appController.navigationController.pushViewController(viewController, animated: animated)
            }
        }
        
        let currentProgress = media is Movie ? WatchedlistManager<Movie>.movie.currentProgress(media.id) : WatchedlistManager<Episode>.episode.currentProgress(media.id)
        var nextEpisode: Episode?
        
        if let showRecipe = productRecipe as? ShowProductRecipe, let episode = media as? Episode {
            
            var episodesLeftInShow = [Episode]()
            
            for season in showRecipe.show.seasonNumbers where season >= showRecipe.season {
                episodesLeftInShow += showRecipe.groupedEpisodes(bySeason: season)
            }
            
            let index = episodesLeftInShow.index(of: episode)!
            episodesLeftInShow.removeFirst(index + 1)
            
            nextEpisode = !episodesLeftInShow.isEmpty ? episodesLeftInShow.removeFirst() : nil
        }
        
        let loadingViewController = storyboard.instantiateViewController(withIdentifier: "LoadingViewController") as! LoadingViewController
        loadingViewController.backgroundImageString = media.largeBackgroundImage
        loadingViewController.mediaTitle = media.title
        present(loadingViewController, true)
        
        let error: (String) -> Void = { (errorMessage) in
            Kitchen.serve(recipe: AlertRecipe(title: "Error", description: errorMessage, buttons: [AlertButton(title: "Okay", actionID: "closeAlert")]))
        }
        
        let finishedLoading: (LoadingViewController, UIViewController) -> Void = { (loadingVc, playerVc) in
            OperationQueue.main.addOperation {
                Kitchen.appController.navigationController.popViewController(animated: true)
            }
            present(playerVc, true)
        }
        
        let playViewController = storyboard.instantiateViewController(withIdentifier: "PCTPlayerViewController") as! PCTPlayerViewController
        playViewController.delegate = self
        
        media.getSubtitles(forId: media.id) { subtitles in
            media.subtitles = subtitles
            
            if let perferredLanguage = SubtitleSettings().language {
                media.currentSubtitle = media.subtitles.first(where: {$0.language == perferredLanguage})
            }
            
            media.play(fromFileOrMagnetLink: torrent.magnet ?? torrent.url, nextEpisodeInSeries: nextEpisode, loadingViewController: loadingViewController, playViewController: playViewController, progress: currentProgress, errorBlock: error, finishedLoadingBlock: finishedLoading)
        }
    }

    /**
     Watch a movies trailer. Handles presenting play view controller and errors thrown by XCDYouTubeKit.
     
     - Parameter code: The 11 digit YouTube identifier of the trailer.
     */
    func playTrailer(_ code: String) {
        let playerController = AVPlayerViewController()
        Kitchen.appController.navigationController.pushViewController(playerController, animated: true)
        XCDYouTubeClient.default().getVideoWithIdentifier(code) { (video, error) in
            guard let streamUrls = video?.streamURLs,
            let qualities = Array(streamUrls.keys) as? [UInt] else { return }
            let preferredVideoQualities = [XCDYouTubeVideoQuality.HD720.rawValue, XCDYouTubeVideoQuality.medium360.rawValue, XCDYouTubeVideoQuality.small240.rawValue]
            var videoUrl: URL?
            forLoop: for quality in preferredVideoQualities {
                if let index = qualities.index(of: quality) {
                    videoUrl = Array(streamUrls.values)[index]
                    break forLoop
                }
            }
            guard let url = videoUrl else {
                Kitchen.appController.navigationController.popViewController(animated: true)
                Kitchen.serve(recipe: AlertRecipe(title: "Oops!", description: "Error fetching valid trailer URL from Youtube.", buttons: [AlertButton(title: "Okay", actionID: "closeAlert")]))
                return
            }
            
            ThemeSongManager.shared.stopTheme()
            
            playerController.player = AVPlayer(url: url)
            playerController.player!.play()
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }
    
    /// Called when AVPlayerViewController stops playing
    func playerDidFinishPlaying() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        OperationQueue.main.addOperation {
            Kitchen.appController.navigationController.popViewController(animated: true)
        }
    }
    
    /**
     Presents UI for picking torrent quality.
     
     - Parameter torrentsString:    A JSON representation of the torrent objects. Use `Mapper` to achieve this.
     - Parameter mediaString:       A JSON representation of the movie or show object. Use `Mapper` to achieve this.
     */
    func chooseQuality(_ torrentsString: String, _ mediaString: String) {
        guard let torrents = Mapper<Torrent>().mapArray(JSONString: torrentsString) else {
            Kitchen.serve(recipe: AlertRecipe(title: "No torrents found", description: "Torrents could not be found for the specified media.", buttons: [AlertButton(title: "Okay", actionID: "closeAlert")]))
            return
        }
        let buttons = torrents.map({ AlertButton(title: $0.quality, actionID: "streamTorrent»\(Mapper<Torrent>().toJSONString($0)?.cleaned ?? "")»\(mediaString.cleaned)") })
        
        guard buttons.count > 1 else {
            guard let id = (try? buttons.first?.get(key: "actionID")) as? String else { return }
            primary(id.dirtied)
            return
        }
        
        Kitchen.serve(recipe: AlertRecipe(title: "Choose Quality", description: "Choose a quality to stream.", buttons: buttons))
    }
    
    // MARK: PCTPlayerViewControllerDelegate
    
    func playNext(_ episode: Episode) {
        chooseQuality(Mapper<Torrent>().toJSONString(episode.torrents) ?? "", Mapper<Episode>().toJSONString(episode) ?? "")
    }
}

extension AlertButton: Value {}
