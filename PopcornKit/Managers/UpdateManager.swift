

import Foundation
import Alamofire
import SwiftyJSON

/**
 `UIApplication.shared` is not accessible from extensions. This delegate is to provide functionality to:
 
 - isCydiaInstalled:    Check for a valid jailbreak.
 - open:cydiaUrl:       And to open a url in the Cydia.app if installed.
 */
public protocol UpdateManagerDelegate: class {
    
    /// Return `UIApplication.shared.canOpenURL(URL(string: "cydia://")!)`
    var isCydiaInstalled: Bool { get }
    
    /**
     Use `UIApplication.shared.openURL:` to open.
     
     - Parameter cydiaUrl: The cydia url to be opened.
     */
    func open(cydiaUrl url: URL)
}

/**
 A manager class that automatically looks for new releases from github and presents them to the user.
 */
public final class UpdateManager: NSObject {
    
    /**
     Determines the frequency in which the the version check is performed.
     
     - .Immediately:    Version check performed every time the app is launched.
     - .Daily:          Version check performedonce a day.
     - .Weekly:         Version check performed once a week.
     */
    public enum CheckType: Int {
        /// Version check performed every time the app is launched.
        case immediately = 0
        /// Version check performed once a day.
        case daily = 1
        /// Version check performed once a week.
        case weekly = 7
    }
    
    /// Current version (CFBundleShortVersionString.CFBundleVersion) of running application.
    private let currentApplicationVersion = "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!).\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!)"
    
    /// Designated Initialiser.
    public static let shared = UpdateManager()
    
    /// Optional delegate for UpdateManager.
    public weak var delegate: UpdateManagerDelegate?
    
    /// The version that the user does not want installed. If the user has never clicked "Skip this version" this variable will be `nil`, otherwise it will be the last version that the user opted not to install.
    private var skipReleaseVersion: VersionString? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "skipReleaseVersion") else { return nil }
            return VersionString.unarchive(data)
        } set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue.archived(), forKey: "skipReleaseVersion")
            } else {
                UserDefaults.standard.removeObject(forKey: "skipReleaseVersion")
            }
        }
    }
    
    /// The date of the last time `checkForUpdates:completion:` was called. If version check was never called, `checkForUpdates:completion:` is called.
    fileprivate var lastVersionCheckPerformedOnDate: Date {
        get {
            return UserDefaults.standard.object(forKey: "lastVersionCheckPerformedOnDate") as? Date ?? {
                checkForUpdates()
                return self.lastVersionCheckPerformedOnDate
                }()
        } set {
            UserDefaults.standard.set(newValue, forKey: "lastVersionCheckPerformedOnDate")
        }
    }
    
    /// Returns the number of days it has been since `checkForUpdates:completion:` has been called.
    private var daysSinceLastVersionCheckDate: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: lastVersionCheckPerformedOnDate, to: Date())
        return components.day!
    }
    
    /**
     Checks github repository for new releases.
     
     - Parameter sucess: Optional callback indicating the status of the operation.
     */
    public func checkVersion(_ checkType: CheckType, completion: ((_ success: Bool) -> Void)? = nil) {
        if checkType == .immediately || checkType.rawValue <= daysSinceLastVersionCheckDate {
            checkForUpdates(completion)
        }
    }
    
    private func checkForUpdates(_ completion: ((_ success: Bool) -> Void)? = nil) {
        lastVersionCheckPerformedOnDate = Date()
        Alamofire.request("https://api.github.com/repos/PopcornTimeTV/PopcornTimeTV/releases").validate().responseJSON { (response) in
            guard let value = response.result.value else { completion?(false); return }
            let responseObject = JSON(value)
            let sortedReleases = responseObject.flatMap({VersionString($1["tag_name"].string!, $1["published_at"].string!)}).sorted(by: {$0.0 > $0.1})

            if let latestRelease = sortedReleases.first,
                let currentRelease = sortedReleases.filter({$0.buildNumber == self.currentApplicationVersion}).first,
                latestRelease > currentRelease && self.skipReleaseVersion?.buildNumber != latestRelease.buildNumber {

                let alert = UIAlertController(title: "Update Available", message: "\(latestRelease.releaseType.rawValue.capitalized) version \(latestRelease.buildNumber) of Popcorn Time is now available.", preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Maybe Later", style: .default, handler: nil))
                
                alert.addAction(UIAlertAction(title: "Skip This Version", style: .default, handler: { (action) in
                    self.skipReleaseVersion = latestRelease
                }))
                
                let isCydiaInstalled = self.delegate?.isCydiaInstalled ?? false
                
                alert.addAction(UIAlertAction(title: isCydiaInstalled ? "Update" : "OK", style: .default, handler: { _ in
                    if isCydiaInstalled {
                        self.delegate?.open(cydiaUrl: URL(string: "cydia://package/\(Bundle.main.bundleIdentifier!)")!)
                    } else {
                        let instructionsAlert = UIAlertController(title: "Sideloading Instructions", message: "Unfortunately, in-app updates are not available for un-jailbroken devices. Please follow the sideloading instructions available in the PopcornTimeTV repo's wiki.", preferredStyle: .alert)
                        instructionsAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        instructionsAlert.show()
                    }
                }))
                completion?(true)
                alert.show()
            } else {
                completion?(false)
            }
        }
    }
}

internal class VersionString: NSObject, NSCoding {
    
    enum ReleaseType: String {
        case beta = "beta"
        case stable = "stable"
    }
    
    let date: Date
    let buildNumber: String
    let releaseType: ReleaseType
    
    init?(_ string: String, _ dateString: String) {
        self.buildNumber = string
        self.date = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            return formatter.date(from: dateString)!
            }()
        
        let components = string.components(separatedBy: ".")
        if let first = components.first, let _ = components[safe: 1], let _ = components[safe: 2] {
            if first == "0" // Beta release. Format will be 0.<major>.<minor>-<patch>.
            {
                self.releaseType = .beta
            } else // Stable release. Format will be <major>.<minor>.<patch>.
            {
                self.releaseType = .stable
            }
            return
        }
        return nil
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(date, forKey: "date")
        aCoder.encode(buildNumber, forKey: "buildNumber")
        aCoder.encode(releaseType.rawValue, forKey: "releaseType")
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let date = aDecoder.decodeObject(forKey: "date") as? Date,
            let buildNumber = aDecoder.decodeObject(forKey: "buildNumber") as? String,
            let releaseTypeRawValue = aDecoder.decodeObject(forKey: "releaseType") as? String,
            let releaseType = ReleaseType(rawValue: releaseTypeRawValue) else { return nil }
        self.date = date
        self.buildNumber = buildNumber
        self.releaseType = releaseType
    }
    
    func archived() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
    class func unarchive(_ data: Data) -> VersionString? {
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? VersionString
    }
}

internal func >(lhs: VersionString, rhs: VersionString) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedDescending
}

internal func <(lhs: VersionString, rhs: VersionString) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedAscending
}

internal func ==(lhs: VersionString, rhs: VersionString) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedSame
}

// MARK: - Extensions

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    public subscript (safe index: Index) -> Iterator.Element? {
        return index >= startIndex && index < endIndex ? self[index] : nil
    }
}

extension UIAlertController {
    public func show() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.windowLevel = UIWindowLevelAlert + 1
        window.makeKeyAndVisible()
        window.rootViewController!.present(self, animated: true)
    }
}
