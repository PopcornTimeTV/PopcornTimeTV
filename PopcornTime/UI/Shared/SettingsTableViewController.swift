

import UIKit
import PopcornKit

class SettingsViewController: UIViewController { }

class SettingsTableViewController: UITableViewController, TraktManagerDelegate {
    
    func authenticationDidSucceed() {
        dismiss(animated: true) {
            let alert = UIAlertController(title: "Success!", message: "Successfully authenticated with Trakt", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        tableView.reloadData()
        TraktManager.shared.syncUserData()
    }
    
    func authenticationDidFail(withError error: NSError) {
        dismiss(animated: true, completion: nil)
        let alert = UIAlertController(title: "Failed to authenticate with Trakt", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                if UIDevice.current.userInterfaceIdiom == .tv {
                    cell.detailTextLabel?.text = "\(Int(UserDefaults.standard.float(forKey: "themeSongVolume") * 100))%"
                } else {
                    cell.detailTextLabel?.text = UserDefaults.standard.bool(forKey: "streamOnCellular") ? "On" : "Off"
                }
            } else if indexPath.row == 1 {
                cell.detailTextLabel?.text = UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit") ? "On" : "Off"
            }
        case 1:
            let subtitleSettings = SubtitleSettings()
            
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = subtitleSettings.language ?? "None"
            } else if indexPath.row == 1 {
                cell.detailTextLabel?.text = subtitleSettings.size.string
            } else if indexPath.row == 2 {
                cell.detailTextLabel?.text = UIColor.systemColors.first(where: {$0 == subtitleSettings.color})?.string ?? ""
            } else if indexPath.row == 3 {
                cell.detailTextLabel?.text = subtitleSettings.font.familyName
            } else if indexPath.row == 4 {
                cell.detailTextLabel?.text = subtitleSettings.style.rawValue
            } else if indexPath.row == 5 {
                cell.detailTextLabel?.text = subtitleSettings.encoding
            }
        case 2 where indexPath.row == 0:
            cell.detailTextLabel?.text = TraktManager.shared.isSignedIn() ? "Sign Out" : "Sign In"
        case 3:
            if indexPath.row == 1 {
                var date = "Never."
                if let lastChecked = UserDefaults.standard.object(forKey: "lastVersionCheckPerformedOnDate") as? Date {
                    date = DateFormatter.localizedString(from: lastChecked, dateStyle: .short, timeStyle: .short)
                }
                cell.detailTextLabel?.text = date
            } else if indexPath.row == 2 {
                cell.detailTextLabel?.text = "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!).\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!)"
            }
        default:
            break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                if UIDevice.current.userInterfaceIdiom == .tv {
                    let handler: (UIAlertAction) -> Void = { action in
                        guard let title = action.title?.replacingOccurrences(of: "%", with: ""),
                            let value = Double(title) else { return }
                        UserDefaults.standard.set(value/100.0, forKey: "themeSongVolume")
                        tableView.reloadData()
                    }
                    
                    let alertController = UIAlertController(title: "Theme Song Volume", message: "Choose a volume for the TV Show and Movie theme songs", preferredStyle: .actionSheet, blurStyle: .dark)
                    
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: "Off", style: .default, handler: { action in
                        UserDefaults.standard.set(0.0, forKey: "themeSongVolume")
                        tableView.reloadData()
                    }))
                    
                    alertController.addAction(UIAlertAction(title: "25%", style: .default, handler: handler))
                    alertController.addAction(UIAlertAction(title: "50%", style: .default, handler: handler))
                    alertController.addAction(UIAlertAction(title: "75%", style: .default, handler: handler))
                    alertController.addAction(UIAlertAction(title: "100%", style: .default, handler: handler))
                    
                    alertController.preferredAction = alertController.actions.first(where: { $0.title == String(Int((UserDefaults.standard.float(forKey: "themeSongVolume") * 100.0))).appending("%") })
                    
                    present(alertController, animated: true, completion: nil)
                } else {
                    let value = UserDefaults.standard.bool(forKey: "streamOnCellular")
                    UserDefaults.standard.set(!value, forKey: "streamOnCellular")
                    tableView.reloadData()
                }
            } else if indexPath.row == 1 {
                let value = UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit")
                UserDefaults.standard.set(!value, forKey: "removeCacheOnPlayerExit")
                tableView.reloadData()
            }
        case 1:
            let subtitleSettings = SubtitleSettings()
            if indexPath.row == 0 {
                let alertController = UIAlertController(title: "Subtitle Language", message: "Choose a default language for the player subtitles.", preferredStyle: .actionSheet, blurStyle: .dark)
                
                let handler: (UIAlertAction) -> Void = { action in
                    subtitleSettings.language = action.title == "None" ? nil : action.title!
                    subtitleSettings.save()
                    tableView.reloadData()
                }
                
                alertController.addAction(UIAlertAction(title: "None", style: .default, handler: handler))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                for language in Locale.commonLanguages {
                    alertController.addAction(UIAlertAction(title: language, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == subtitleSettings.language }) ?? alertController.actions.first(where: { $0.title == "None" })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true, completion: nil)
            } else if indexPath.row == 1 {
                let alertController = UIAlertController(title: "Subtitle Font Size", message: "Choose a font size for the player subtitles.", preferredStyle: .actionSheet, blurStyle: .dark)
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                let handler: (UIAlertAction) -> Void = { action in
                    subtitleSettings.size = SubtitleSettings.Size.array.first(where: {$0.string == action.title})!
                    subtitleSettings.save()
                    tableView.reloadData()
                }
                
                for size in SubtitleSettings.Size.array {
                    alertController.addAction(UIAlertAction(title: size.string, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == subtitleSettings.size.string })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true, completion: nil)
            } else if indexPath.row == 2 {
                let alertController = UIAlertController(title: "Subtitle Color", message: "Choose text color for the player subtitles.", preferredStyle: .actionSheet, blurStyle: .dark)
                
                let handler: (UIAlertAction) -> Void = { action in
                    subtitleSettings.color = UIColor.systemColors.first(where: {$0.string == action.title}) ?? .white
                    subtitleSettings.save()
                    tableView.reloadData()
                }
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                for title in UIColor.systemColors.flatMap({$0.string}) {
                    alertController.addAction(UIAlertAction(title: title, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == subtitleSettings.color.string })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true, completion: nil)
            } else if indexPath.row == 3 {
                let alertController = UIAlertController(title: "Subtitle Font", message: "Choose a default font for the player subtitles.", preferredStyle: .actionSheet, blurStyle: .dark)
                
                let handler: (UIAlertAction) -> Void = { action in
                    guard let familyName = action.title,
                        let fontName = UIFont.fontNames(forFamilyName: familyName).first,
                        let font = UIFont(name: fontName, size: 16) else { return }
                    subtitleSettings.font = font
                    subtitleSettings.save()
                    tableView.reloadData()
                }
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                for language in UIFont.familyNames {
                    alertController.addAction(UIAlertAction(title: language, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == subtitleSettings.font.familyName })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true, completion: nil)
            } else if indexPath.row == 4 {
                
                let alertController = UIAlertController(title: "Subtitle Font Style", message: "Choose a default font style for the player subtitles.", preferredStyle: .actionSheet, blurStyle: .dark)
                
                let handler: (UIAlertAction) -> Void = { action in
                    subtitleSettings.style = UIFont.FontStyle(rawValue: action.title!)!
                    subtitleSettings.save()
                    tableView.reloadData()
                }
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                for style in UIFont.FontStyle.arrayValue.map({$0.rawValue}) {
                    alertController.addAction(UIAlertAction(title: style, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == subtitleSettings.style.rawValue })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true, completion: nil)
            } else if indexPath.row == 5,
                let path = Bundle.main.path(forResource: "EncodingTypes", ofType: "plist"),
                let labels = NSDictionary(contentsOfFile: path) as? [String: [String]],
                let titles = labels["Titles"],
                let values = labels["Values"]  {
                
                let alertController = UIAlertController(title: "Subtitle Encoding", message: "Choose encoding for the player subtitles.", preferredStyle: .actionSheet, blurStyle: .dark)
                
                let handler: (UIAlertAction) -> Void = { action in
                    subtitleSettings.encoding = values[titles.index(of: action.title!)!]
                    subtitleSettings.save()
                    tableView.reloadData()
                }
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                for title in titles {
                    alertController.addAction(UIAlertAction(title: title, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == titles[values.index(of: subtitleSettings.encoding)!] })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true, completion: nil)
            }
        case 2 where indexPath.row == 0 :
            if TraktManager.shared.isSignedIn() {
                let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to Sign Out?", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
                    do { try TraktManager.shared.logout() } catch { }
                    tableView.reloadData()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            } else {
                TraktManager.shared.delegate = self
                let vc = TraktManager.shared.loginViewController()
                present(vc, animated: true, completion: nil)
            }
        case 3:
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
                        controller.message = "Cleaned \(ByteCountFormatter.string(fromByteCount: size, countStyle: .binary))."
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
                    label.font = UIDevice.current.userInterfaceIdiom == .tv ? UIFont.systemFont(ofSize: 37) : UIFont.systemFont(ofSize: 16, weight: UIFontWeightBold)
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
                    alert.dismiss(animated: true) {
                        if !success {
                            let alert = UIAlertController(title: "No Updates Available", message: "There are no updates available for Popcorn Time at this time.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self?.present(alert, animated: true, completion: nil)
                        }
                        tableView.reloadData() 
                    }
                }
            }
        default:
            break
        }
    }
}

#if os(tvOS)
    
    import TVMLKitchen
    
    extension SettingsTableViewController {
        override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
            OperationQueue.main.addOperation {
                Kitchen.navigationController.present(viewControllerToPresent, animated: flag, completion: completion)
            }
        }
        
        override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
            OperationQueue.main.addOperation {
                Kitchen.navigationController.dismiss(animated: flag, completion: completion)
            }
        }
    }
#endif
