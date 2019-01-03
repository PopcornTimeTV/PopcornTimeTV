

import UIKit
import PopcornKit
import Reachability
import ObjectMapper

#if os(iOS)
    import AlamofireNetworkActivityIndicator
    import GoogleCast
#endif

#if os(tvOS)
    import TVServices
#endif

public let vlcSettingTextEncoding = "subsdec-encoding"

struct ColorPallete {
    let primary: UIColor
    let secondary: UIColor
    let tertiary: UIColor
    
    private init(primary: UIColor, secondary: UIColor, tertiary: UIColor) {
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
    }
    
    static let light = ColorPallete(primary: .white, secondary: UIColor.white.withAlphaComponent(0.667), tertiary: UIColor.white.withAlphaComponent(0.333))
    static let dark  = ColorPallete(primary: .black, secondary: UIColor.black.withAlphaComponent(0.667), tertiary: UIColor.black.withAlphaComponent(0.333))
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {
    
    static var shared: AppDelegate = UIApplication.shared.delegate as! AppDelegate

    var window: UIWindow?
    
    var reachability: Reachability = .forInternetConnection()
    
    var tabBarController: UITabBarController {
        return window?.rootViewController as! UITabBarController
    }
    
    var activeRootViewController: MainViewController? {
        guard
            let navigationController = tabBarController.selectedViewController as? UINavigationController,
            let main = navigationController.viewControllers.compactMap({$0 as? MainViewController}).first
            else {
                return nil
        }
        return main
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if os(tvOS)
            if let url = launchOptions?[.url] as? URL {
                return self.application(.shared, open: url)
            }
            NotificationCenter.default.post(name: NSNotification.Name.TVTopShelfItemsDidChange, object: nil)
            let font = UIFont.systemFont(ofSize: 38, weight: UIFont.Weight.heavy)
            UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
        #elseif os(iOS)
            NetworkActivityIndicatorManager.shared.isEnabled = true
            
            // SDK throws error if shared instance has already been initialised and doesn't mark function as throwing on Swift. Although this produces a compile time warning, it is necessary for the app to not crash while running on an actual device and should not be removed.
             GCKCastContext.setSharedInstanceWith(GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID))) 
            
            tabBarController.delegate = self

        #endif
        
        if !UserDefaults.standard.bool(forKey: "tosAccepted") {
            let vc = UIStoryboard.main.instantiateViewController(withIdentifier: "TermsOfServiceNavigationController")
            window?.makeKeyAndVisible()
            UserDefaults.standard.set(0.75, forKey: "themeSongVolume")
            OperationQueue.main.addOperation {
                self.activeRootViewController?.present(vc, animated: false) {
                    self.activeRootViewController?.environmentsToFocus = [self.tabBarController.tabBar]
                }
            }
        }
        
        reachability.startNotifier()
        window?.tintColor = .app
        
        TraktManager.shared.syncUserData()
        awakeObjects()
        
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if tabBarController.selectedViewController == viewController, let scrollView = viewController.view.recursiveSubviews.compactMap({$0 as? UIScrollView}).first {
            let offset = CGPoint(x: 0, y: -scrollView.contentInset.top)
            scrollView.setContentOffset(offset, animated: true)
        }
        return true
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        #if os(tvOS)
            if url.scheme == "PopcornTime" {
                guard
                    let actions = url.absoluteString.removingPercentEncoding?.components(separatedBy: "PopcornTime:?action=").last?.components(separatedBy: "»"),
                    let type = actions.first, let json = actions.last
                    else {
                        return false
                }
                
                let media: Media = type == "showMovie" ? Mapper<Movie>().map(JSONString: json)! : Mapper<Show>().map(JSONString: json)!
                
                if let vc = activeRootViewController {
                    let storyboard = UIStoryboard.main
                    let loadingViewController = storyboard.instantiateViewController(withIdentifier: "LoadingViewController")
                    
                    let segue = AutoPlayStoryboardSegue(identifier: type, source: vc, destination: loadingViewController)
                    vc.prepare(for: segue, sender: media)
                    
                    tabBarController.tabBar.isHidden = true
                    vc.navigationController?.push(loadingViewController, animated: true)
                }
            }
        #elseif os(iOS)
            if let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, (sourceApplication == "com.apple.SafariViewService" || sourceApplication == "com.apple.mobilesafari") && url.scheme == "popcorntime" {
                TraktManager.shared.authenticate(url)
            } else if url.scheme == "magnet" || url.isFileURL {
                let torrentUrl: String
                let id: String
                
                if url.scheme == "magnet" {
                    torrentUrl = url.absoluteString
                    id = torrentUrl
                } else {
                    torrentUrl = url.path
                    id = url.lastPathComponent
                }
                
                let torrent = Torrent(url: torrentUrl)
                let media: Media = Movie(id: id, torrents: [torrent]) // Type here is arbitrary.
                
                play(media, torrent: torrent)
            }
        #endif
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UpdateManager.shared.checkVersion(.daily)
    }
    
    func awakeObjects() {
        let typeCount = Int(objc_getClassList(nil, 0))
        let types = UnsafeMutablePointer<AnyClass?>.allocate(capacity: typeCount)
        let autoreleasingTypes = AutoreleasingUnsafeMutablePointer<AnyObject.Type>(types)
        objc_getClassList(autoreleasingTypes, Int32(typeCount))
        for index in 0 ..< typeCount { (types[index] as? Object.Type)?.awake() }
        types.deallocate()
    }
}
