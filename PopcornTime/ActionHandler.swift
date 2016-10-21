

import TVMLKitchen
import PopcornKit
import PopcornTorrent
import AVKit
import XCDYouTubeKit
import ObjectMapper

class ActionHandler: NSObject {
    
    static let shared = ActionHandler()
    
    
    func performSelector(named methodSignature: String, parameters: [String]) {
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

     - parameter id: The actionID of the element pressed
     */
    func primary(_ id: String) {
        var pieces = id.components(separatedBy: "»")
        performSelector(named: pieces.removeFirst(), parameters: pieces)
    }
    
    /**
     The action handler for when the play button is pressed
     - parameter id: The actionID of the element pressed
     */
    func play(_ id: String) {
        
    }
    
    func addMovieToWatchlist(_ movieString: String) {
        guard let movie = Mapper<Movie>().map(JSONString: movieString) else { return }
        WatchlistManager<Movie>.movie.add(movie)
        Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
            context.objectForKeyedSubscript("updateWatchlistButton").call(withArguments: [])
            }, completion: nil)
    }
    
    func addShowToWatchlist(_ showString: String) {
        guard let show = Mapper<Show>().map(JSONString: showString) else { return }
        WatchlistManager<Show>.show.add(show)
        Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
            context.objectForKeyedSubscript("updateWatchlistButton").call(withArguments: [])
            }, completion: nil)
    }
    
    func showDescription(_ title: String, _ message: String) {
        Kitchen.serve(recipe: DescriptionRecipe(title: title, message: message))
    }
    
    func closeAlert() {
        Kitchen.dismissModal()
    }
    
    // MARK: - Movies
    
    func showMovies() {
        Kitchen.serve(recipe: KitchenTabBar(items: [Trending(.movies), Popular(.movies), Latest(.movies), Genre(.movies), Watchlist(.movies), Search(.movies)]))
    }
    
    func showMovie(_ title: String, _ id: String) {
        Kitchen.serve(recipe: LoadingRecipe(message: title))
        
        PopcornKit.getMovieInfo(id) { (movie, error) in
            guard var movie = movie else {
                var viewcontrollers = Kitchen.navigationController.viewControllers
                viewcontrollers.removeLast()
                Kitchen.navigationController.setViewControllers(viewcontrollers, animated: true)
                Kitchen.serve(recipe: AlertRecipe(title: "Failed to load movie.", description: error?.code == 4 ? "No torrents available for selected movie." : error!.localizedDescription, buttons: [AlertButton(title: "Okay", actionID: "closeAlert")]))
                return
            }
            
            let group = DispatchGroup()
            
            group.enter()
            TraktManager.shared.getRelated(movie, completion: { (movies, _) in
                movie.related = movies
                group.leave()
            })
            
            group.enter()
            TraktManager.shared.getPeople(forMediaOfType: .movies, id: id, completion: { (actors, crew, _) in
                movie.actors = actors
                movie.crew = crew
                group.leave()
            })
            
            group.notify(queue: .main, execute: {
                let recipe =  MovieProductRecipe(movie: movie)
                Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
                    
                    if let file = Bundle.main.url(forResource: "MovieProductRecipe", withExtension: "js") {
                        do {
                            let js = try String(contentsOf: file).replacingOccurrences(of: "{{RECIPE}}", with: recipe.xmlString)
                            context.evaluateScript(js)
                        } catch {
                            print("Could not open MovieProductRecipe.js")
                        }
                    }
                    }, completion: nil)
                self.dismissLoading()
            })
        }
    }
    
    func dismissLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            var viewcontrollers = Kitchen.navigationController.viewControllers
            viewcontrollers.remove(at: viewcontrollers.count-2)
            Kitchen.navigationController.setViewControllers(viewcontrollers, animated: false)
        })
    }
    
    // MARK: - Shows
    
    func showTVShows() {
        Kitchen.serve(recipe: KitchenTabBar(items: [Trending(.shows), Popular(.shows), Latest(.shows), Genre(.shows), Watchlist(.shows), Search(.shows)]))
    }
    
    func showGlobalWatchlist() {
        Kitchen.serve(recipe: LoadingRecipe(message:"Loading..."))
        
        var recipe = WatchlistRecipe(title: "Favourites")
        
        recipe.watchListMovies = WatchlistManager<Movie>.movie.getWatchlist { (movies) in
            recipe.watchListMovies = movies
        }
        
        recipe.watchListShows = WatchlistManager<Show>.show.getWatchlist { (shows) in
            recipe.watchListShows = shows
        }
        Kitchen.serve(recipe: recipe)
        dismissLoading()
    }

    func showSettings() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController {
            OperationQueue.main.addOperation({ 
                Kitchen.appController.navigationController.pushViewController(viewController, animated: true)
            })
        }
    }

    func serveCatalogRecipe(_ recipe: CatalogRecipe, topBarHidden hidden: Bool = false) {
        Kitchen.appController.evaluate(inJavaScriptContext: { jsContext in
            let highlightLockup: @convention(block) (Int, JSValue) -> () = {(nextPage, callback) in
                if callback.isObject {
                    recipe.lockup(didChangePage: nextPage, completion: { (lockUp) in
                        callback.call(withArguments: [lockUp])
                    })
                }
            }
            jsContext.setObject(unsafeBitCast(highlightLockup, to: AnyObject.self), forKeyedSubscript: "highlightLockup" as (NSCopying & NSObjectProtocol)!)

            if let file = Bundle.main.url(forResource: "Pagination", withExtension: "js") {
                do {
                    var js = try String(contentsOf: file).replacingOccurrences(of: "{{RECIPE}}", with: recipe.xmlString)
                    if hidden { js = js.replacingOccurrences(of: "{{TYPE}}", with: "catalog") }
                    jsContext.evaluateScript(js)
                } catch {
                    print("Could not open Pagination.js")
                }
            }

            }, completion: nil)
    }
    

    func showMovieGenre(_ genre: String) {
        guard let genre = MovieManager.Genres(rawValue: genre) else { return }
        Kitchen.serve(recipe: LoadingRecipe(message: genre.rawValue))
        
        var recipe: CatalogRecipe!
        recipe = CatalogRecipe(title: genre.rawValue, fetchBlock: { (page, completion) in
            PopcornKit.loadMovies(page, genre: genre, completion: { (movies, error) in
                guard let movies = movies else { return }
                completion(movies.map({$0.lockUp}).joined(separator: ""))
                self.serveCatalogRecipe(recipe, topBarHidden: true)
                self.dismissLoading()
            })
        })
    }
    
    func showShowGenre(_ genre: String) {
        guard let genre = ShowManager.Genres(rawValue: genre) else { return }
        Kitchen.serve(recipe: LoadingRecipe(message: genre.rawValue))
        
        var recipe: CatalogRecipe!
        recipe = CatalogRecipe(title: genre.rawValue, fetchBlock: { (page, completion) in
            PopcornKit.loadShows(page, genre: genre, completion: { (shows, error) in
                guard let shows = shows else {  return }
                completion(shows.map({$0.lockUp}).joined(separator: ""))
                self.serveCatalogRecipe(recipe, topBarHidden: true)
                self.dismissLoading()
            })
        })
    }

    func showMovieCredits(_ name: String, _ id: String) {
        Kitchen.serve(recipe: LoadingRecipe(message: name))
        
        var recipe: CatalogRecipe!
        recipe = CatalogRecipe(title: name, fetchBlock: { (page, completion) in
            TraktManager.shared.getMediaCredits(forPersonWithId: id, mediaType: Movie.self) { (movies, error) in
                guard !movies.isEmpty else { return }
                completion(movies.map({$0.lockUp}).joined(separator: ""))
                self.serveCatalogRecipe(recipe, topBarHidden: true)
                self.dismissLoading()
            }
        })
    }
    
    func showShowCredits(_ name: String, _ id: String) {
        Kitchen.serve(recipe: LoadingRecipe(message: name))
        
        var recipe: CatalogRecipe!
        recipe = CatalogRecipe(title: name, fetchBlock: { (page, completion) in
            TraktManager.shared.getMediaCredits(forPersonWithId: id, mediaType: Show.self) { (shows, error) in
                guard !shows.isEmpty else { return }
                completion(shows.map({$0.lockUp}).joined(separator: ""))
                self.serveCatalogRecipe(recipe, topBarHidden: true)
                self.dismissLoading()
            }
        })
    }

    func showShow(_ title: String, _ id: String) {
        Kitchen.serve(recipe: LoadingRecipe(message: title))
        
        PopcornKit.getShowInfo(id) { (show, error) in
            guard var show = show else { return }
            
            let group = DispatchGroup()
            
            group.enter()
            TraktManager.shared.getRelated(show, completion: { (shows, _) in
                show.related = shows
                group.leave()
            })
            
            group.enter()
            TraktManager.shared.getPeople(forMediaOfType: .shows, id: id, completion: { (actors, crew, _) in
                show.actors = actors
                show.crew = crew
                group.leave()
            })
            
            group.enter()
            self.loadEpisodeMetadata(forShow: show) { episodes in
                show.episodes = episodes
                group.leave()
            }
            
            group.notify(queue: .main, execute: {
                var recipe = SeasonProductRecipe(show: show)
                Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
                    let disableThemeSong: @convention(block) (String) -> Void = { message in
                        AudioManager.shared.stopTheme()
                    }
                    
                    let updateSeason: @convention(block) (Int, JSValue) -> Void = { (number, callback) in
                        recipe.season = number
                        callback.call(withArguments: [recipe.template])
                    }
                    
                    context.setObject(unsafeBitCast(updateSeason, to: AnyObject.self),
                                      forKeyedSubscript: "updateSeason" as (NSCopying & NSObjectProtocol)!)
                    
                    context.setObject(unsafeBitCast(disableThemeSong, to: AnyObject.self),
                                      forKeyedSubscript: "disableThemeSong" as (NSCopying & NSObjectProtocol)!)
                    
                    if let file = Bundle.main.url(forResource: "SeasonProductRecipe", withExtension: "js") {
                        do {
                            let js = try String(contentsOf: file).replacingOccurrences(of: "{{RECIPE}}", with: recipe.xmlString)
                            context.evaluateScript(js)
                        } catch {
                            print("Could not open SeasonProductRecipe.js")
                        }
                    }
                    }, completion: nil)
                self.dismissLoading()
            })
        }
    }
    
    func showSeasons(_ showString: String, _ episodesString: String) {
        guard var show = Mapper<Show>().map(JSONString: showString), let episodes = Mapper<Episode>().mapArray(JSONString: episodesString) else { return }
        show.episodes = episodes
        TraktManager.shared.getSeasonMetadata(forShowId: show.id, seasons: show.seasonNumbers) { (images, error) in
            guard !images.isEmpty && error == nil else { return }
            let recipe = SeasonPickerRecipe(show: show, seasonImages: images)
            Kitchen.serve(recipe: recipe)
        }
    }
    
    func showSeason(_ number: String) {
        Kitchen.appController.evaluate(inJavaScriptContext: { (context) in
            context.objectForKeyedSubscript("changeSeason").call(withArguments: [Int(number)!])
            }, completion: nil)
    }
    
    func loadEpisodeMetadata(forShow show: Show, completion: @escaping ([Episode]) -> Void) {
        let group = DispatchGroup()
        
        var episodes = [Episode]()
        
        for var episode in show.episodes {
            group.enter()
            TraktManager.shared.getEpisodeMetadata(show.id, episodeNumber: episode.episode, seasonNumber: episode.season, completion: { (image, _, _, error) in
                if let image = image { episode.largeBackgroundImage = image }
                episodes.append(episode)
                group.leave()
            })
        }
        
        group.notify(queue: .main, execute: {
            episodes.sort(by: { $0.episode < $1.episode })
            completion(episodes)
        })
    }

    func streamTorrent(_ torrentString: String, _ mediaString: String) {
        guard let media: Media = Mapper<Movie>().map(JSONString: mediaString) ?? Mapper<Show>().map(JSONString: mediaString),
                let torrent = Mapper<Torrent>().map(JSONString: torrentString) else { return }
        
        Kitchen.dismissModal()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let present: (UIViewController, Bool) -> Void = { (viewController, animated) in
            OperationQueue.main.addOperation({
                Kitchen.appController.navigationController.pushViewController(viewController, animated: animated)
            })
        }
        
        let currentProgress = WatchedlistManager.movie.currentProgress(media.id)
        
        let loadingViewController = storyboard.instantiateViewController(withIdentifier: "LoadingViewController") as! LoadingViewController
        loadingViewController.backgroundImageString = media is Movie ? media.largeCoverImage : media.largeBackgroundImage
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
        
        media.play(fromFileOrMagnetLink: torrent.magnet ?? torrent.url, loadingViewController: loadingViewController, playViewController: playViewController, progress: currentProgress, errorBlock: error, finishedLoadingBlock: finishedLoading)

    }

    func playTrailer(_ code: String) {
        let playerController = AVPlayerViewController()
        Kitchen.appController.navigationController.pushViewController(playerController, animated: true)
        XCDYouTubeClient.default().getVideoWithIdentifier(code) { (video, error) in
            guard let streamUrls = video?.streamURLs else { return }
            let preferredVideoQualities = [XCDYouTubeVideoQuality.HD720, XCDYouTubeVideoQuality.medium360, XCDYouTubeVideoQuality.small240]
            var videoUrl: URL?
            forLoop: for quality in preferredVideoQualities {
                if let url = streamUrls[quality] {
                    videoUrl = url
                    break forLoop
                }
            }
            guard let url = videoUrl else { return }
            playerController.player = AVPlayer(url: url)
            playerController.player!.play()
        }
    }
    
    func playMedia(_ torrentString: String, _ mediaString: String) {
        guard let torrents = Mapper<Torrent>().mapArray(JSONString: torrentString) else {
            Kitchen.serve(recipe: AlertRecipe(title: "No torrents found", description: "Torrents could not be found for the specified movie.", buttons: [AlertButton(title: "Okay", actionID: "closeAlert")]))
            return
        }
        let buttons = torrents.map({ AlertButton(title: $0.quality, actionID: "streamTorrent»\(Mapper<Torrent>().toJSONString($0)?.cleaned ?? "")»\(mediaString.cleaned)") })
        
        Kitchen.serve(recipe: AlertRecipe(title: "Choose Quality", description: "Choose a quality to stream.", buttons: buttons))
    }
}
