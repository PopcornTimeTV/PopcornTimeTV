

import UIKit
import PopcornKit
import TVMLKitchen

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TraktManagerDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var settingsIcon: UIImageView!

    let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.contentInset = UIEdgeInsets(top: 100, left: -50, bottom: 0, right: 0)
        self.settingsIcon.image = UIImage(named: "settings.png")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Table View

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 3
        case 2: return 3
        case 3: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "TV Shows"
        case 1: return "Player"
        case 2: return "Other"
        case 3: return "Trakt"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Theme Song Volume"
                
                let volume = (UserDefaults.standard.object(forKey: "TVShowVolume") as? NSNumber) ?? NSNumber(value: 0.75)
                cell.detailTextLabel?.text = "\(Int(volume.doubleValue * 100))%"
                cell.accessoryType = .none
            }

        case 1:
            guard let settings = SQSubSetting.loadFromDisk() else {
                break
            }
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Font Size"
                if settings.sizeFloat == 20.0 {
                    cell.detailTextLabel?.text = "Small"
                } else if settings.sizeFloat == 16.0 {
                    cell.detailTextLabel?.text = "Medium"
                } else if settings.sizeFloat == 12.0 {
                    cell.detailTextLabel?.text = "Medium Large"
                } else if settings.sizeFloat == 6.0 {
                    cell.detailTextLabel?.text = "Large"
                }
                cell.accessoryType = .none
            }else if indexPath.row == 1 {
                cell.textLabel?.text = "Subtitle Background"
                switch settings.backgroundType {
                case .blur: cell.detailTextLabel?.text = "Blur"
                case .black: cell.detailTextLabel?.text = "Black"
                case .white: cell.detailTextLabel?.text = "White"
                case .none: cell.detailTextLabel?.text = "None"
                }
                cell.accessoryType = .none
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Subtitle Encoding"
                cell.detailTextLabel?.text = settings.encoding
                cell.accessoryType = .none
            }

        case 2:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Clear All Cache"
                cell.detailTextLabel?.text = ""
                cell.accessoryType = .none
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Start web server"
                if let startWebServer = UserDefaults.standard.object(forKey: "StartWebServer") as? Bool {
                    cell.detailTextLabel?.text = startWebServer ? "Yes" : "No"
                } else {
                    cell.detailTextLabel?.text = "No"
                }
                cell.accessoryType = .none
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Version"
                cell.detailTextLabel?.text = "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!) (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!))"
                cell.accessoryType = .none
            }
    
        case 3:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Sign into Trakt"
                cell.detailTextLabel?.text = ""
                if TraktManager.shared.isSignedIn() {
                    cell.textLabel?.text = "Signout from Trakt"
                }
                cell.accessoryType = .none
            }
    
        default: break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                // Log Out
                let alertController = UIAlertController(title: "TV Show Theme Song Volume", message: "Choose a volume for the TV Show theme songs", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: "Off", style: .default, handler: { action in
                    UserDefaults.standard.set(0.0, forKey: "TVShowVolume")
                    tableView.reloadData()
                }))

                alertController.addAction(UIAlertAction(title: "25%", style: .default, handler: { action in
                    UserDefaults.standard.set(0.25, forKey: "TVShowVolume")
                    tableView.reloadData()
                }))

                alertController.addAction(UIAlertAction(title: "50%", style: .default, handler: { action in
                    UserDefaults.standard.set(0.5, forKey: "TVShowVolume")
                    tableView.reloadData()
                }))

                alertController.addAction(UIAlertAction(title: "75%", style: .default, handler: { action in
                    UserDefaults.standard.set(0.75, forKey: "TVShowVolume")
                    tableView.reloadData()
                }))

                alertController.addAction(UIAlertAction(title: "100%", style: .default, handler: { action in
                    UserDefaults.standard.set(1.0, forKey: "TVShowVolume")
                    tableView.reloadData()
                }))

                self.present(alertController, animated: true, completion: nil)
            }

        case 1:
            if let settings = SQSubSetting.loadFromDisk() {
                if indexPath.row == 0 {
                    let alertController = UIAlertController(title: "Subtitle Font Size", message: "Choose a font size for subtitles.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                    alertController.addAction(UIAlertAction(title: "Small (46pts)", style: .default, handler: { action in
                        settings.sizeFloat = 20.0
                        settings.writeToDisk()
                        tableView.reloadData()
                    }))

                    alertController.addAction(UIAlertAction(title: "Medium (56pts)", style: .default, handler: { action in
                        settings.sizeFloat = 16.0
                        settings.writeToDisk()
                        tableView.reloadData()
                    }))

                    alertController.addAction(UIAlertAction(title: "Medium Large (66pts)", style: .default, handler: { action in
                        settings.sizeFloat = 12.0
                        settings.writeToDisk()
                        tableView.reloadData()
                    }))

                    alertController.addAction(UIAlertAction(title: "Large (96pts)", style: .default, handler: { action in
                        settings.sizeFloat = 6.0
                        settings.writeToDisk()
                        tableView.reloadData()
                    }))

                    self.present(alertController, animated: true, completion: nil)
                }

                if indexPath.row == 1 {
                    let alertController = UIAlertController(title: "Subtitle Background", message: "Choose a background for the subtitles.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                    alertController.addAction(UIAlertAction(title: "Blur", style: .default, handler: { action in
                        settings.backgroundType = .blur
                        settings.writeToDisk()
                        tableView.reloadData()
                    }))

                    alertController.addAction(UIAlertAction(title: "Black", style: .default, handler: { action in
                        settings.backgroundType = .black
                        settings.writeToDisk()
                        tableView.reloadData()
                    }))

                    alertController.addAction(UIAlertAction(title: "White", style: .default, handler: { action in
                        settings.backgroundType = .white
                        settings.writeToDisk()
                        tableView.reloadData()
                    }))

                    alertController.addAction(UIAlertAction(title: "None", style: .default, handler: { action in
                        settings.backgroundType = .none
                        settings.writeToDisk()
                        tableView.reloadData()

                    }))

                    self.present(alertController, animated: true, completion: nil)
                }
                
                if indexPath.row == 2 {
                    let alertController = UIAlertController(title: "Subtitle Encoding", message: "Choose an encoding for the subtitles.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                    let path = Bundle.main.path(forResource: "encodingTypes", ofType: "plist")
                    let labels = NSDictionary.init(contentsOfFile: path!)
                    let titles = labels!["Titles"] as! [String]
                    let values = labels!["Values"] as! [String]
                    for (i, title) in titles.enumerated() {
                        alertController.addAction(UIAlertAction(title: title, style: .default, handler: { action in
                            let encoding = values[i]
                            settings.encoding = encoding
                            settings.writeToDisk()
                            tableView.reloadData()
                        }))
                    }
                    self.present(alertController, animated: true, completion: nil)
                }
            }

        case 2:
            if indexPath.row == 0 {
                let alertController = UIAlertController(title: "Clear Cache", message: "Clearing the cache will delete any unused images, incomplete torrent downloads and subtitles.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Clear Cache", style: .destructive, handler: { action in
                    self.clearCache()
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            } else if indexPath.row == 1 {
                var ip = WebServerManager.sharedManager().getWiFiAddress()
                if ip == nil {
                    ip = WebServerManager.sharedManager().getLANAddress()
                }
                let alertController = UIAlertController(title: "Start Web Sever", message: "Starts a web server that allows you to browse to PopcornTimeTV from any browser http://\(ip!):8181 and view the downloaded media.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                    UserDefaults.standard.set(true, forKey: "StartWebServer")
                    WebServerManager.sharedManager().startServer(port: 8181)
                    tableView.reloadData()
                }))
                alertController.addAction(UIAlertAction(title: "No", style: .default, handler: { action in
                    UserDefaults.standard.set(false, forKey: "StartWebServer")
                    WebServerManager.sharedManager().stopServer()
                    tableView.reloadData()
                }))
                self.present(alertController, animated: true, completion: nil)
            }

            if indexPath.row == 2 {
                UpdateManager.shared.checkVersion(.immediately) { updateAvailable in
                    // If an update was available the UpdateManager would have alread prompted
                    if !updateAvailable {
                        let alertController = UIAlertController(title: "No Updates Available", message: "You are using the latest version, \(self.version), however, if you are a developer, there might be a minor update avaible as a commit, you are using commit \(self.build), check https://github.com/PopcornTimeTV/PopcornTimeTV to see if new commits are available.", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        case 3:
            if indexPath.row == 0{
                if TraktManager.shared.isSignedIn() {
                    TraktManager.shared.logout()
                    self.tableView.reloadData()
                } else{
                    TraktManager.shared.delegate = self
                    let vc = TraktManager.shared.loginViewController()
                    present(vc, animated:true, completion:nil)
                }
                
            }
        default: break
        }
    }

    func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        return IndexPath(row: 0, section: 0)
    }

    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        settingsIcon.image = UIImage(named: "settings.png")
        return true
    }

    func clearCache() {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if let cachesDirectory = paths.first {
            guard let subs = try? FileManager.default.contentsOfDirectory(atPath: cachesDirectory) else {
                return
            }
            for item in subs {
                _ = try? FileManager.default.removeItem(atPath: (cachesDirectory as NSString).appendingPathComponent(item))
            }
        }
    }

    // MARK: Navigation
    
    func authenticationDidSucceed() {
        tableView.reloadData()
    }
}
