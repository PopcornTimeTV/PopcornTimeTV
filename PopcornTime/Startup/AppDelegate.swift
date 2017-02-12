

import UIKit
import PopcornKit

#if os(tvOS)
    import TVMLKitchen
#elseif os(iOS)
    import Reachability
    import AlamofireNetworkActivityIndicator
    import GoogleCast
#endif

public let animationLength = 0.33
public let vlcSettingTextEncoding = "subsdec-encoding"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UpdateManagerDelegate, UITabBarControllerDelegate {

    var window: UIWindow?
    
    #if os(iOS)
        var reachability = Reachability.forInternetConnection()
    #elseif os(tvOS)
    
        func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
            
            let cookbook = Cookbook(launchOptions: launchOptions)
            
            cookbook.actionIDHandler = ActionHandler.shared.primary
            cookbook.playActionIDHandler = ActionHandler.shared.primary
            
            Kitchen.prepare(cookbook)
            
            ActionHandler.shared.cookbook = cookbook
        
            return true
        }
    #endif

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        #if os(tvOS)
            
            if let url = launchOptions?[.url] as? URL {
                self.application(.shared, open: url)
                return true
            }
            
            ActionHandler.shared.loadTabBar() {
                if !UserDefaults.standard.bool(forKey: "tosAccepted") {
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TermsOfServiceViewController")
                    OperationQueue.main.addOperation {
                        Kitchen.appController.navigationController.pushViewController(vc, animated: true)
                    }
                    UserDefaults.standard.set(0.75, forKey: "themeSongVolume")
                }
            }
            
            
        #elseif os(iOS)
            NetworkActivityIndicatorManager.shared.isEnabled = true
            reachability?.startNotifier()
            
            /// Weird SDK throws error if shared instance has already been initialised and doesn't mark function as throwing.
            do { try GCKCastContext.setSharedInstanceWith(GCKCastOptions(receiverApplicationID: kGCKMediaDefaultReceiverApplicationID)) }
            window?.tintColor = UIColor.app
            
            if !UserDefaults.standard.bool(forKey: "tosAccepted") {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TermsOfServiceNavigationController")
                window?.makeKeyAndVisible()
                window?.rootViewController?.present(vc, animated: false, completion: nil)
                UserDefaults.standard.set("720p", forKey: "preferredQuality")
            }
        #endif
            
        TraktManager.shared.syncUserData()
        UpdateManager.shared.delegate = self
        
        (window?.rootViewController as? UITabBarController)?.delegate = self
        
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if tabBarController.selectedViewController == viewController, let scrollView = viewController.view.recursiveSubviews.flatMap({$0 as? UIScrollView}).first {
            let offset = CGPoint(x: 0, y: -scrollView.contentInset.top)
            scrollView.setContentOffset(offset, animated: true)
        }
        return true
    }
    
    @discardableResult func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        #if os(tvOS)
            if url.scheme == "PopcornTime" {
                guard let action = url.absoluteString.removingPercentEncoding?.components(separatedBy: "PopcornTime:?action=").last else {
                    return false
                }
                if Kitchen.appController.navigationController.viewControllers.first != nil // Don't present WelcomeRecipe if it is already there.
                {
                    ActionHandler.shared.primary(action)
                } else {
                    ActionHandler.shared.loadTabBar() {
                        ActionHandler.shared.primary(action)
                    }
                }
            }
        #elseif os(iOS)
            if let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, (sourceApplication == "com.apple.SafariViewService" || sourceApplication == "com.apple.mobilesafari") && url.scheme == "popcorntime" {
                TraktManager.shared.authenticate(url)
                return true
            }
        #endif
        
        if url.scheme == "magnet" {
            // TODO: Manget links
        }
        
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
    
    var isCydiaInstalled: Bool {
        return UIApplication.shared.canOpenURL(URL(string: "cydia://")!)
    }
    
    func open(cydiaUrl url: URL) {
        UIApplication.shared.openURL(url)
    }
}
