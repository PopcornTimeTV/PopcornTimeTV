

import UIKit
import PopcornKit
import Reachability
import ObjectMapper

#if os(iOS)
    import AlamofireNetworkActivityIndicator
    import GoogleCast
#endif

public let vlcSettingTextEncoding = "subsdec-encoding"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

    var window: UIWindow?
    
    var reachability: Reachability = .forInternetConnection()
    
    var tabBarController: UITabBarController {
        return window?.rootViewController as! UITabBarController
    }
    
    var activeRootViewController: MainViewController? {
        guard
            let navigationController = tabBarController.selectedViewController as? UINavigationController,
            let main = navigationController.viewControllers.flatMap({$0 as? MainViewController}).first
            else {
                return nil
        }
        return main
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        #if os(tvOS)
            if let url = launchOptions?[.url] as? URL {
                return self.application(.shared, open: url)
            }
        #elseif os(iOS)
            NetworkActivityIndicatorManager.shared.isEnabled = true
            
            // Weird SDK throws error if shared instance has already been initialised and doesn't mark function as throwing.
            do { try GCKCastContext.setSharedInstanceWith(GCKCastOptions(receiverApplicationID: kGCKMediaDefaultReceiverApplicationID)) }
            
            (window?.rootViewController as? UITabBarController)?.delegate = self

        #endif
        
        if !UserDefaults.standard.bool(forKey: "tosAccepted") {
            let vc = UIStoryboard.main.instantiateViewController(withIdentifier: "TermsOfServiceNavigationController")
            window?.makeKeyAndVisible()
            UserDefaults.standard.set(0.25, forKey: "themeSongVolume")
            OperationQueue.main.addOperation {
                self.window?.rootViewController?.present(vc, animated: false)
            }
        }
        
        reachability.startNotifier()
        window?.tintColor = .app
        
        TraktManager.shared.syncUserData()
        awakeObjects()
        
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if tabBarController.selectedViewController == viewController, let scrollView = viewController.view.recursiveSubviews.flatMap({$0 as? UIScrollView}).first {
            let offset = CGPoint(x: 0, y: -scrollView.contentInset.top)
            scrollView.setContentOffset(offset, animated: true)
        }
        return true
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
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
            if let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, (sourceApplication == "com.apple.SafariViewService" || sourceApplication == "com.apple.mobilesafari") && url.scheme == "popcorntime" {
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
                
                if let root = window?.rootViewController {
                    let type = type(of: root)
                    object_setClass(root, DetailViewController.self)
                    let vc = root as! DetailViewController
                    object_setIvar(vc, class_getInstanceVariable(DetailViewController.self, NSString(string: "currentItem").utf8String), media)
                    vc.play(media, torrent: torrent)
                    object_setClass(root, type)
                }
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
    
    func applicationWillTerminate(_ application: UIApplication) {
        SubtitlesManager.shared.logout()
    }
    
    func awakeObjects() {
        let typeCount = Int(objc_getClassList(nil, 0))
        let types = UnsafeMutablePointer<AnyClass?>.allocate(capacity: typeCount)
        let autoreleasingTypes = AutoreleasingUnsafeMutablePointer<AnyClass?>(types)
        objc_getClassList(autoreleasingTypes, Int32(typeCount))
        for index in 0 ..< typeCount { (types[index] as? Object.Type)?.awake() }
        types.deallocate(capacity: typeCount)
    }
}
