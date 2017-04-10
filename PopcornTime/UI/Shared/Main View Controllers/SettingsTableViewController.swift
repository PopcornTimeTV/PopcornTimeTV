

import UIKit
import class PopcornKit.TraktManager
import class PopcornKit.UpdateManager
import protocol PopcornKit.TraktManagerDelegate

class SettingsTableViewController: UITableViewController, TraktManagerDelegate {
    
    func authenticationDidSucceed() {
        dismiss(animated: true) {
            let alert = UIAlertController(title: "Success".localized, message: "Successfully authenticated with Trakt".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized, style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
        tableView.reloadData()
        TraktManager.shared.syncUserData()
    }
    
    func authenticationDidFail(with error: NSError) {
        dismiss(animated: true)
        let alert = UIAlertController(title: "Failed to authenticate with Trakt".localized, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.current.userInterfaceIdiom == .tv {
            tableView.contentInset.bottom = 27
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                if UIDevice.current.userInterfaceIdiom == .tv {
                    cell.detailTextLabel?.text = NumberFormatter.localizedString(from: NSNumber(value: UserDefaults.standard.float(forKey: "themeSongVolume")), number: .percent)
                } else {
                    cell.detailTextLabel?.text = UserDefaults.standard.bool(forKey: "streamOnCellular") ? "On".localized : "Off".localized
                }
            } else if indexPath.row == 1 {
                cell.detailTextLabel?.text = UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit") ? "On".localized : "Off".localized
            } else if indexPath.row == 2 {
                cell.detailTextLabel?.text = UserDefaults.standard.string(forKey: "autoSelectQuality") ?? "Off".localized
            }
        case 1:
            let subtitleSettings = SubtitleSettings.shared
            
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = subtitleSettings.language ?? "None".localized
            } else if indexPath.row == 1 {
                cell.detailTextLabel?.text = subtitleSettings.size.string
            } else if indexPath.row == 2 {
                cell.detailTextLabel?.text = UIColor.systemColors.first(where: {$0 == subtitleSettings.color})?.localizedString ?? ""
            } else if indexPath.row == 3 {
                cell.detailTextLabel?.text = subtitleSettings.font.familyName
            } else if indexPath.row == 4 {
                cell.detailTextLabel?.text = subtitleSettings.style.rawValue
            } else if indexPath.row == 5 {
                cell.detailTextLabel?.text = subtitleSettings.encoding
            }
        case 2 where indexPath.row == 0:
            cell.detailTextLabel?.text = TraktManager.shared.isSignedIn() ? "Sign Out".localized : "Sign In".localized
        case 3:
            if indexPath.row == 1 {
                var date = "Never".localized
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
                    
                    let alertController = UIAlertController(title: "Theme Song Volume".localized, message: "Choose a volume for the TV Show and Movie theme songs.".localized, preferredStyle: .actionSheet, blurStyle: .dark)
                    
                    alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: "Off".localized, style: .default, handler: { action in
                        UserDefaults.standard.set(0.0, forKey: "themeSongVolume")
                        tableView.reloadData()
                    }))
                    
                    alertController.addAction(UIAlertAction(title: NumberFormatter.localizedString(from: NSNumber(value: 0.25), number: .percent), style: .default, handler: handler))
                    alertController.addAction(UIAlertAction(title: NumberFormatter.localizedString(from: NSNumber(value: 0.5), number: .percent), style: .default, handler: handler))
                    alertController.addAction(UIAlertAction(title: NumberFormatter.localizedString(from: NSNumber(value: 0.75), number: .percent), style: .default, handler: handler))
                    alertController.addAction(UIAlertAction(title: NumberFormatter.localizedString(from: NSNumber(value: 1), number: .percent), style: .default, handler: handler))
                    
                    
                    alertController.preferredAction = alertController.actions.first(where: { $0.title == NumberFormatter.localizedString(from: NSNumber(value: UserDefaults.standard.float(forKey: "themeSongVolume")), number: .percent) })
                    
                    present(alertController, animated: true)
                } else {
                    let value = UserDefaults.standard.bool(forKey: "streamOnCellular")
                    UserDefaults.standard.set(!value, forKey: "streamOnCellular")
                    tableView.reloadData()
                }
            } else if indexPath.row == 1 {
                let value = UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit")
                UserDefaults.standard.set(!value, forKey: "removeCacheOnPlayerExit")
                tableView.reloadData()
            } else if indexPath.row == 2 {
                let alertController = UIAlertController(title: "Auto Select Quality".localized, message: "Choose a default quality. If said quality is available, it will be automatically selected.".localized, preferredStyle: .actionSheet, blurStyle: .dark)
                
                let handler: (UIAlertAction) -> Void = { action in
                    let value = action.title == "Off".localized ? nil : action.title
                    UserDefaults.standard.set(value, forKey: "autoSelectQuality")
                    tableView.reloadData()
                }
                
                alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                
                for quality in ["Off".localized, "Highest".localized, "Lowest".localized] {
                    alertController.addAction(UIAlertAction(title: quality, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == UserDefaults.standard.string(forKey: "autoSelectQuality") ?? "Off".localized })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true)
            }
        case 1:
            let subtitleSettings = SubtitleSettings.shared
            if indexPath.row == 0 {
                let alertController = UIAlertController(title: "Subtitle Language".localized, message: "Choose a default language for the player subtitles.".localized, preferredStyle: .actionSheet, blurStyle: .dark)
                
                let handler: (UIAlertAction) -> Void = { action in
                    subtitleSettings.language = action.title == "None".localized ? nil : action.title!
                    subtitleSettings.save()
                    tableView.reloadData()
                }
                
                alertController.addAction(UIAlertAction(title: "None".localized, style: .default, handler: handler))
                alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                
                for language in Locale.commonLanguages {
                    alertController.addAction(UIAlertAction(title: language, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == subtitleSettings.language }) ?? alertController.actions.first(where: { $0.title == "None".localized })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true)
            } else if indexPath.row == 1 {
                let alertController = UIAlertController(title: "Subtitle Font Size".localized, message: "Choose a font size for the player subtitles.".localized, preferredStyle: .actionSheet, blurStyle: .dark)
                
                alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                
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
                
                present(alertController, animated: true)
            } else if indexPath.row == 2 {
                let alertController = UIAlertController(title: "Subtitle Color".localized, message: "Choose text color for the player subtitles.".localized, preferredStyle: .actionSheet, blurStyle: .dark)
                
                let handler: (UIAlertAction) -> Void = { action in
                    subtitleSettings.color = UIColor.systemColors.first(where: {$0.localizedString == action.title}) ?? .white
                    subtitleSettings.save()
                    tableView.reloadData()
                }
                
                alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                
                for title in UIColor.systemColors.flatMap({$0.localizedString}) {
                    alertController.addAction(UIAlertAction(title: title, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == subtitleSettings.color.localizedString })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true)
            } else if indexPath.row == 3 {
                let alertController = UIAlertController(title: "Subtitle Font".localized, message: "Choose a default font for the player subtitles.".localized, preferredStyle: .actionSheet, blurStyle: .dark)
                
                let handler: (UIAlertAction) -> Void = { action in
                    guard let familyName = action.title,
                        let fontName = UIFont.fontNames(forFamilyName: familyName).first,
                        let font = UIFont(name: fontName, size: 16) else { return }
                    subtitleSettings.font = font
                    subtitleSettings.save()
                    tableView.reloadData()
                }
                
                alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                
                for language in UIFont.familyNames {
                    alertController.addAction(UIAlertAction(title: language, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == subtitleSettings.font.familyName })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true)
            } else if indexPath.row == 4 {
                
                let alertController = UIAlertController(title: "Subtitle Font Style".localized, message: "Choose a default font style for the player subtitles.".localized, preferredStyle: .actionSheet, blurStyle: .dark)
                
                let handler: (UIAlertAction) -> Void = { action in
                    subtitleSettings.style = UIFont.Style(rawValue: action.title!)!
                    subtitleSettings.save()
                    tableView.reloadData()
                }
                
                alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                
                for style in UIFont.Style.arrayValue.map({$0.rawValue}) {
                    alertController.addAction(UIAlertAction(title: style, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == subtitleSettings.style.rawValue })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true)
            } else if indexPath.row == 5 {
                let keys   = Array(SubtitleSettings.encodings.keys)
                let values = Array(SubtitleSettings.encodings.values)
                
                let alertController = UIAlertController(title: "Subtitle Encoding".localized, message: "Choose encoding for the player subtitles.".localized, preferredStyle: .actionSheet, blurStyle: .dark)
                
                let handler: (UIAlertAction) -> Void = { action in
                    subtitleSettings.encoding = values[keys.index(of: action.title!)!]
                    subtitleSettings.save()
                    tableView.reloadData()
                }
                
                alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                
                for title in keys {
                    alertController.addAction(UIAlertAction(title: title, style: .default, handler: handler))
                }
                
                alertController.preferredAction = alertController.actions.first(where: { $0.title == keys[values.index(of: subtitleSettings.encoding)!] })
                
                alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                
                present(alertController, animated: true)
            }
        case 2 where indexPath.row == 0 :
            if TraktManager.shared.isSignedIn() {
                let alert = UIAlertController(title: "Sign Out".localized, message: "Are you sure you want to Sign Out?".localized, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Sign Out".localized, style: .destructive, handler: { action in
                    do { try TraktManager.shared.logout() } catch { }
                    tableView.reloadData()
                }))
                alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                present(alert, animated: true)
            } else {
                TraktManager.shared.delegate = self
                let vc = TraktManager.shared.loginViewController()
                present(vc, animated: true)
            }
        case 3:
            if indexPath.row == 0 {
                let controller = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "OK".localized, style: .cancel, handler: nil))
                do {
                    let size = FileManager.default.folderSize(atPath: NSTemporaryDirectory())
                    for path in try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory()) {
                        try FileManager.default.removeItem(atPath: NSTemporaryDirectory() + "/\(path)")
                    }
                    controller.title = "Success".localized
                    if size == 0 {
                        controller.message = "Cache was already empty, no disk space was reclamed.".localized
                    } else {
                        controller.message = "Cleaned".localized + " \(ByteCountFormatter.string(fromByteCount: size, countStyle: .binary))."
                    }
                } catch {
                    controller.title = "Failed".localized
                    controller.message = "Error cleaning cache.".localized
                }
                present(controller, animated: true)
            } else if indexPath.row == 1 {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                let contentViewController = UIStoryboard.main.instantiateViewController(withIdentifier: "CheckForUpdatesViewController")
                alert.setValue(contentViewController, forKey: "contentViewController")
                alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                present(alert, animated: true)
                UpdateManager.shared.checkVersion(.immediately) { [weak self] success in
                    alert.dismiss(animated: true) {
                        if !success {
                            let alert = UIAlertController(title: "No Updates Available".localized, message: "There are no updates available for Popcorn Time at this time.".localized, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))
                            self?.present(alert, animated: true)
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
