

import UIKit
import TVMLKitchen
import PopcornKit
import Alamofire
import GCDWebServer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let cookbook = Cookbook(launchOptions: launchOptions)
        cookbook.actionIDHandler = ActionHandler.primary
        cookbook.playActionIDHandler = ActionHandler.play
        Kitchen.prepare(cookbook)
        /*
        Alamofire.request(.GET, "https://api.ipify.org/?format=json").responseJSON { response in
            print(response.result.value)
        }
         */
        if let webServer = NSUserDefaults.standardUserDefaults().objectForKey("StartWebServer") as? Bool {
            if webServer {
                WebServerManager.sharedManager().startServer(8181)
            }
        }

        let manager = NetworkManager.sharedManager()
        manager.fetchServers { servers, error in
            if let servers = servers {
                if let yts = servers["yts"] as? [String],
                   let eztv = servers["eztv"] as? [String],
                   let kat = servers["kat"] as? [String] {
                    manager.setServerEndpoints(yts: yts.first!, eztv: eztv.first!, kat: kat.first!)

                    // Save the amount of TV Show pages
                    manager.fetchShowPageNumbers({ (pageNumbers, error) in
                        if let pageNumbers = pageNumbers {
                            NSUserDefaults.standardUserDefaults().setObject(pageNumbers, forKey: "EZTVPageCount")
                        }
                    })

                    manager.fetchShowsForPage(1) { shows, error in
                        if let shows = shows {
                            manager.fetchMovies(limit: 50, page: 1, quality: "1080p", minimumRating: 3, queryTerm: nil, genre: nil, sortBy: "seeds", orderBy: "desc", withImages: true) { movies, error in
                                if let movies = movies {
                                    let watchlist = WatchlistManager.sharedManager()
                                    watchlist.fetchWatchListItems(forType: .Movie) { watchListMovies in
                                        watchlist.fetchWatchListItems(forType: .Show) { watchListShows in
                                            Kitchen.serve(recipe: WelcomeRecipe(title: "PopcornTime", movies: movies, shows: shows, watchListMovies: watchListMovies, watchListShows: watchListShows))

                                            if let url = launchOptions?[UIApplicationLaunchOptionsURLKey] as? NSURL {
                                                self.handleURL(url)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                }
            }
        }

        SubtitleManager.sharedManager().cleanSubs()

        return true
    }

    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        if url.host == nil {
            return true
        }



        return true
    }

    func handleURL(url: NSURL) {
        let urlString = url.absoluteString
        let queryArray = urlString.componentsSeparatedByString("/")

        let action = queryArray[2..<queryArray.endIndex].joinWithSeparator("»")

        ActionHandler.primary(action)
    }

    func checkForUpdates() {
        if let currentVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String {
            UpdateManager.sharedManager().checkForUpdates(forVersion: currentVersion) { (updateAvailable, name, releaseNotes, error) in
                if updateAvailable {
                    Kitchen.serve(recipe: AlertRecipe(title: "Update Available", description: "A new version of PopcornTime is available.\n\(name!)\n\n\(releaseNotes!)\n\nVisit https://github.com/PopcornTimeTV/PopcornTimeTV to update.", buttons: [AlertButton(title: "Okay", actionID: "closeAlert")], presentationType: .Modal))
                }
            }
        }
    }
}
