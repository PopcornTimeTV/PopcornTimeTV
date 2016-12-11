

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
                #if os(tvOS)
                    cell.detailTextLabel?.text = "\(Int(UserDefaults.standard.float(forKey: "themeSongVolume") * 100))%"
                #elseif os(iOS)
                    cell.detailTextLabel?.text = UserDefaults.standard.bool(forKey: "streamOnCellular") ? "On" : "Off"
                #endif
            } else if indexPath.row == 1 {
                cell.detailTextLabel?.text = UserDefaults.standard.string(forKey: "preferredQuality") ?? "1080p"
            } else if indexPath.row == 2 {
                cell.detailTextLabel?.text = UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit") ? "On" : "Off"
            }
        case 1:
            let subtitleSettings = SubtitleSettings()
            
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = subtitleSettings.language ?? "None"
            } else if indexPath.row == 1 {
                switch subtitleSettings.size {
                case 20.0 : cell.detailTextLabel?.text = "Small"
                case 16.0 : cell.detailTextLabel?.text = "Medium"
                case 12.0 : cell.detailTextLabel?.text = "Medium Large"
                case 6.0  : cell.detailTextLabel?.text = "Large"
                default: break
                }
            } else if indexPath.row == 2 {
                let index = UIColor.systemColors.index(of: subtitleSettings.color)!
                cell.detailTextLabel?.text = UIColor.systemColorStrings[index]
            } else if indexPath.row == 3 {
                cell.detailTextLabel?.text = subtitleSettings.font.familyName
            } else if indexPath.row == 4 {
                cell.detailTextLabel?.text = subtitleSettings.style.rawValue
            } else if indexPath.row == 5 {
                cell.detailTextLabel?.text = subtitleSettings.encoding
            }
        case 2:
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = TraktManager.shared.isSignedIn() ? "Sign Out" : "Sign In"
            } else if indexPath.row == 1 {
                cell.detailTextLabel?.text = UserDefaults.standard.bool(forKey: "authorizedOpenSubs") ? "Sign Out" : "Sign In"
            }
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
                #if os(tvOS)
                    let handler: (UIAlertAction) -> Void = { action in
                        guard let title = action.title?.replacingOccurrences(of: "%", with: ""),
                            let value = Double(title) else { return }
                        UserDefaults.standard.set(value/100.0, forKey: "themeSongVolume")
                        tableView.reloadData()
                    }
                    
                    let alertController = UIAlertController(title: "Theme Song Volume", message: "Choose a volume for the TV Show and Movie theme songs", preferredStyle: .actionSheet)
                    
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
                #elseif os(iOS)
                    let value = UserDefaults.standard.bool(forKey: "streamOnCellular")
                    UserDefaults.standard.set(!value, forKey: "streamOnCellular")
                    tableView.reloadData()
                #endif
            } else if indexPath.row == 1 {
                let handler: (UIAlertAction) -> Void = { action in
                    UserDefaults.standard.setValue(action.title!, forKey: "preferredQuality")
                    tableView.reloadData()
                }
                let alertController = UIAlertController(title: "Preferred Quality", message: "Choose your preferred quality for torrents and they will be automatically selected whenever available.", preferredStyle: .actionSheet)
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                alertController.addAction(UIAlertAction(title: "1080p", style: .default, handler: handler))
                alertController.addAction(UIAlertAction(title: "720p", style: .default, handler: handler))
                alertController.addAction(UIAlertAction(title: "480p", style: .default, handler: handler))
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == UserDefaults.standard.string(forKey: "preferredQuality") ?? "1080p" })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true, completion: nil)
            } else if indexPath.row == 2 {
                let value = UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit")
                UserDefaults.standard.set(!value, forKey: "removeCacheOnPlayerExit")
                tableView.reloadData()
            }
        case 1:
            let subtitleSettings = SubtitleSettings()
            if indexPath.row == 0 {
                let alertController = UIAlertController(title: "Subtitle Language", message: "Choose a default language for the player subtitles.", preferredStyle: .actionSheet)
                
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
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == subtitleSettings.language })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true, completion: nil)
            } else if indexPath.row == 1 {
                let alertController = UIAlertController(title: "Subtitle Font Size", message: "Choose a font size for the player subtitles.", preferredStyle: .actionSheet)
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                alertController.addAction(UIAlertAction(title: "Small (46pts)", style: .default, handler: { action in
                    subtitleSettings.size = 20.0
                    subtitleSettings.save()
                    tableView.reloadData()
                }))
                
                alertController.addAction(UIAlertAction(title: "Medium (56pts)", style: .default, handler: { action in
                    subtitleSettings.size = 16.0
                    subtitleSettings.save()
                    tableView.reloadData()
                }))
                
                alertController.addAction(UIAlertAction(title: "Medium Large (66pts)", style: .default, handler: { action in
                    subtitleSettings.size = 12.0
                    subtitleSettings.save()
                    tableView.reloadData()
                }))
                
                alertController.addAction(UIAlertAction(title: "Large (96pts)", style: .default, handler: { action in
                    subtitleSettings.size = 6.0
                    subtitleSettings.save()
                    tableView.reloadData()
                }))
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true, completion: nil)
            } else if indexPath.row == 2 {
                let alertController = UIAlertController(title: "Subtitle Color", message: "Choose text color for the player subtitles.", preferredStyle: .actionSheet)
                
                let handler: (UIAlertAction) -> Void = { action in
                    subtitleSettings.color = UIColor.systemColors[UIColor.systemColorStrings.index(of: action.title!)!]
                    subtitleSettings.save()
                    tableView.reloadData()
                }
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                for title in UIColor.systemColorStrings {
                    alertController.addAction(UIAlertAction(title: title, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == UIColor.systemColorStrings[UIColor.systemColors.index(of: subtitleSettings.color)!] })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true, completion: nil)
            } else if indexPath.row == 3 {
                let alertController = UIAlertController(title: "Subtitle Font", message: "Choose a default font for the player subtitles.", preferredStyle: .actionSheet)
                
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
                
                let alertController = UIAlertController(title: "Subtitle Font Style", message: "Choose a default font style for the player subtitles.", preferredStyle: .actionSheet)
                
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
                
                let alertController = UIAlertController(title: "Subtitle Encoding", message: "Choose encoding for the player subtitles.", preferredStyle: .actionSheet)
                
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
        case 2:
            if indexPath.row == 0 {
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
            } else if indexPath.row == 1 {
                if UserDefaults.standard.bool(forKey: "authorizedOpenSubs") {
                    let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to Sign Out?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
                        
                        let credential = URLCredentialStorage.shared.credentials(for: SubtitlesManager.shared.protectionSpace)!.values.first!
                        URLCredentialStorage.shared.remove(credential, for: SubtitlesManager.shared.protectionSpace)
                        UserDefaults.standard.set(false, forKey: "authorizedOpenSubs")
                        tableView.reloadData()
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    present(alert, animated: true, completion: nil)
                } else {
                    var alert = UIAlertController(title: "Sign In", message: "VIP account required.", preferredStyle: .alert)
                    alert.addTextField(configurationHandler: { (textField) in
                        textField.placeholder = "Username"
                    })
                    alert.addTextField(configurationHandler: { (textField) in
                        textField.placeholder = "Password"
                        textField.isSecureTextEntry = true
                    })
                    alert.addAction(UIAlertAction(title: "Sign In", style: .default, handler: { (action) in
                        let credential = URLCredential(user: alert.textFields![0].text!, password: alert.textFields![1].text!, persistence: .permanent)
                        URLCredentialStorage.shared.set(credential, for: SubtitlesManager.shared.protectionSpace)
                        SubtitlesManager.shared.login() { error in
                            if let error = error {
                                URLCredentialStorage.shared.remove(credential, for: SubtitlesManager.shared.protectionSpace)
                                alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            } else {
                                UserDefaults.standard.set(true, forKey: "authorizedOpenSubs")
                                tableView.reloadData()
                            }
                        }
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    present(alert, animated: true, completion: nil)
                }
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
                    label.font = UIDevice.current.userInterfaceIdiom == .tv ? UIFont.systemFont(ofSize: 37) : UIFont.systemFont(ofSize: 16, weight: UIFontWeightBold)
                    label.sizeToFit()
                    #if os(tvOS)
                        let style = UIActivityIndicatorViewStyle.white
                    #elseif os(iOS)
                        let style = UIActivityIndicatorViewStyle.gray
                    #endif
                    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: style)
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
