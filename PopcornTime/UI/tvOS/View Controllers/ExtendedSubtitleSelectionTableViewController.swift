//
//  ExtendedSubtitleSelectionTableViewController.swift
//  PopcornTimetvOS
//
//  Created by Aggelos Papageorgiou on 09/11/2018.
//  Copyright © 2018 PopcornTime. All rights reserved.
//

import UIKit
import struct PopcornKit.Subtitle

class ExtendedSubtitleSelectionTableViewController: UITableViewController {

    var allSubtitles = Dictionary<String, [Subtitle]>()
    var currentSubtitle:Subtitle?
    var delegate:SubtitlesViewControllerDelegate?
    
    private var previousCell:UITableViewCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Always 2 sections, the selection section and the subtitles section
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }else{
            return currentSubtitle != nil ? Array(allSubtitles[currentSubtitle!.language]!).count : 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        
        if indexPath.section == 0{
            cell = tableView.dequeueReusableCell(withIdentifier: "LangCell")!
            cell.detailTextLabel?.text = currentSubtitle?.language ?? "None".localized
        }else{
            cell = tableView.dequeueReusableCell(withIdentifier: "SubCell")!
            let subtitle = Array(allSubtitles[currentSubtitle?.language ?? "English"]!)[indexPath.row]
            cell.detailTextLabel?.text = subtitle.language
            cell.textLabel?.text = subtitle.name
            cell.accessoryType = currentSubtitle?.name == subtitle.name ? .checkmark : .none
            currentSubtitle?.name == subtitle.name ? previousCell = cell : ()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.section == 0 {
            let alertController = UIAlertController(title: "Select Language".localized, message: nil, preferredStyle: .actionSheet)
            
            var allLanguages = Array(allSubtitles.keys)
            allLanguages.sort()
            for (language) in allLanguages{
                        let action = UIAlertAction(title: language, style: .default) { _ in
                            // subtitles api needs to be updated for this to work
                            self.currentSubtitle = alternateSubtiles.first
                            cell?.detailTextLabel?.text = language
                            tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .fade)
                            self.delegate?.didSelectSubtitle(self.currentSubtitle)
                        }
                        alertController.addAction(action)
            }
            alertController.show(animated: true)
        }else{
            delegate?.didSelectSubtitle(currentSubtitle)
            self.currentSubtitle = Array(allSubtitles[currentSubtitle!.language]!)[indexPath.row]
            previousCell?.accessoryType = .none
            cell?.accessoryType = .checkmark
            previousCell = cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Available Subtitles".localized
        }
        return ""
    }
}
