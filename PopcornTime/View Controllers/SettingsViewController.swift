

import UIKit
import PopcornKit
import TVMLKitchen

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TraktManagerDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var settingsIcon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.contentInset = UIEdgeInsets(top: 100, left: -50, bottom: 0, right: 0)
        self.settingsIcon.image = UIImage(named: "settings.png")
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
        case 0: return "Theme Music"
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
                
                let volume = (UserDefaults.standard.object(forKey: "ThemeSongVolume") as? NSNumber) ?? NSNumber(value: 0.75)
                cell.detailTextLabel?.text = "\(Int(volume.doubleValue * 100))%"
                cell.accessoryType = .none
            }

        case 1:
            let settings = SubtitleSettings()
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Font Size"
                if settings.fontSize == 20.0 {
                    cell.detailTextLabel?.text = "Small"
                } else if settings.fontSize == 16.0 {
                    cell.detailTextLabel?.text = "Medium"
                } else if settings.fontSize == 12.0 {
                    cell.detailTextLabel?.text = "Medium Large"
                } else if settings.fontSize == 6.0 {
                    cell.detailTextLabel?.text = "Large"
                }
                cell.accessoryType = .none
            }else if indexPath.row == 1 {
                cell.textLabel?.text = "Subtitle Background"
                cell.detailTextLabel?.text = settings.backgroundType.rawValue
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
                cell.textLabel?.text = "Check for updates"
                var date = "Never."
                if let lastChecked = UserDefaults.standard.object(forKey: "lastVersionCheckPerformedOnDate") as? Date {
                    date = DateFormatter.localizedString(from: lastChecked, dateStyle: .short, timeStyle: .short)
                }
                cell.detailTextLabel?.text = "Last checked: \(date)"
                cell.accessoryType = .none
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Version"
                cell.detailTextLabel?.text = "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!).\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!)"
                cell.accessoryType = .none
            }
    
        case 3:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Sign into Trakt"
                cell.detailTextLabel?.text = ""
                if TraktManager.shared.isSignedIn() {
                    cell.textLabel?.text = "Sign out from Trakt"
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
                let alertController = UIAlertController(title: "Theme Song Volume", message: "Choose a volume for the TV Show and Movie theme songs", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: "Off", style: .default, handler: { action in
                    UserDefaults.standard.set(0.0, forKey: "TVShowVolume")
                    tableView.reloadData()
                }))

                alertController.addAction(UIAlertAction(title: "25%", style: .default, handler: { action in
                    UserDefaults.standard.set(0.25, forKey: "ThemeSongVolume")
                    tableView.reloadData()
                }))

                alertController.addAction(UIAlertAction(title: "50%", style: .default, handler: { action in
                    UserDefaults.standard.set(0.5, forKey: "ThemeSongVolume")
                    tableView.reloadData()
                }))

                alertController.addAction(UIAlertAction(title: "75%", style: .default, handler: { action in
                    UserDefaults.standard.set(0.75, forKey: "ThemeSongVolume")
                    tableView.reloadData()
                }))

                alertController.addAction(UIAlertAction(title: "100%", style: .default, handler: { action in
                    UserDefaults.standard.set(1.0, forKey: "ThemeSongVolume")
                    tableView.reloadData()
                }))

                self.present(alertController, animated: true, completion: nil)
            }

        case 1:
            let settings = SubtitleSettings()
                if indexPath.row == 0 {
                    let alertController = UIAlertController(title: "Subtitle Font Size", message: "Choose a font size for subtitles.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                    alertController.addAction(UIAlertAction(title: "Small (46pts)", style: .default, handler: { action in
                        settings.fontSize = 20.0
                        settings.save()
                        tableView.reloadData()
                    }))

                    alertController.addAction(UIAlertAction(title: "Medium (56pts)", style: .default, handler: { action in
                        settings.fontSize = 16.0
                        settings.save()
                        tableView.reloadData()
                    }))

                    alertController.addAction(UIAlertAction(title: "Medium Large (66pts)", style: .default, handler: { action in
                        settings.fontSize = 12.0
                        settings.save()
                        tableView.reloadData()
                    }))

                    alertController.addAction(UIAlertAction(title: "Large (96pts)", style: .default, handler: { action in
                        settings.fontSize = 6.0
                        settings.save()
                        tableView.reloadData()
                    }))

                    self.present(alertController, animated: true, completion: nil)
                }

                if indexPath.row == 1 {
                    let alertController = UIAlertController(title: "Subtitle Background", message: "Choose a background for the subtitles.", preferredStyle: .alert)
                    let handler: (UIAlertAction) -> Void = { action in
                        settings.backgroundType = BackgroundType(rawValue: action.title!)!
                        settings.save()
                        tableView.reloadData()
                    }
                    
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                    alertController.addAction(UIAlertAction(title: "Blur", style: .default, handler: handler))

                    alertController.addAction(UIAlertAction(title: "Black", style: .default, handler: handler))

                    alertController.addAction(UIAlertAction(title: "White", style: .default, handler: handler))

                    alertController.addAction(UIAlertAction(title: "None", style: .default, handler: handler))

                    self.present(alertController, animated: true, completion: nil)
                }
                
            if indexPath.row == 2,
                let path = Bundle.main.path(forResource: "EncodingTypes", ofType: "plist"),
                let labels = NSDictionary(contentsOfFile: path) as? [String: [String]],
                let titles = labels["Titles"],
                let values = labels["Values"]  {
                    let alertController = UIAlertController(title: "Subtitle Encoding", message: "Choose an encoding for the subtitles.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                    for (index, title) in titles.enumerated() {
                        alertController.addAction(UIAlertAction(title: title, style: .default, handler: { action in
                            let encoding = values[index]
                            settings.encoding = encoding
                            settings.save()
                            tableView.reloadData()
                        }))
                    }
                    self.present(alertController, animated: true, completion: nil)
                }
        case 2:
            if indexPath.row == 0 {
                let controller = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                do {
                    let size = FileManager.default.folderSize(atPath: NSTemporaryDirectory())
                    for path in try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory()) {
                        try FileManager.default.removeItem(atPath: NSTemporaryDirectory() + "/\(path)")
                    }
                    controller.title = "Success"
                    if size == 0 {
                        controller.message = "Cache was already empty, no disk space was reclamed."
                    } else {
                        controller.message = "Cleaned \(size) bytes."
                    }
                } catch {
                    controller.title = "Failed"
                    controller.message = "Error cleaning cache."
                    print("Error: \(error)")
                }
                present(controller, animated: true, completion: nil)
            } else if indexPath.row == 1 {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                let loadingView: UIViewController = {
                    let viewController = UIViewController()
                    viewController.view.translatesAutoresizingMaskIntoConstraints = false
                    let label = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 200, height: 20)))
                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.text = "Checking for updates..."
                    label.font = UIFont.systemFont(ofSize: 37)
                    label.sizeToFit()
                    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
                    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
                    activityIndicator.startAnimating()
                    viewController.view.addSubview(activityIndicator)
                    viewController.view.addSubview(label)
                    viewController.view.centerXAnchor.constraint(equalTo: label.centerXAnchor, constant: -10).isActive = true
                    viewController.view.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
                    label.leadingAnchor.constraint(equalTo: activityIndicator.trailingAnchor, constant: 10).isActive = true
                    viewController.view.centerYAnchor.constraint(equalTo: activityIndicator.centerYAnchor).isActive = true
                    return viewController
                }()
                alert.setValue(loadingView, forKey: "contentViewController")
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
                UpdateManager.shared.checkVersion(.immediately) { [weak self] success in
                    alert.dismiss(animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                        if !success {
                            let alert = UIAlertController(title: "No Updates Available", message: "There are no updates available for Popcorn Time at this time.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self?.present(alert, animated: true, completion: nil)
                        }
                        self?.tableView.reloadData()
                    })
                    
                }
            }
        case 3:
            if indexPath.row == 0 {
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

    // MARK: TraktManagerDelegate
    
    func authenticationDidSucceed() {
        dismiss(animated: true, completion: nil)
        tableView.reloadData()
    }
    
    func authenticationDidFail(withError error: NSError) {
        dismiss(animated: true, completion: nil)
        Kitchen.serve(recipe: AlertRecipe(title: "Failed to authenticate with Trakt", description: error.localizedDescription, buttons: [AlertButton(title: "Okay", actionID: "closeAlert")], presentationType: .modal))
    }
}
