//
//  ExtendedSubtitleViewController.swift
//  PopcornTimetvOS
//
//  Created by Aggelos Papageorgiou on 09/11/2018.
//  Copyright © 2018 PopcornTime. All rights reserved.
//

import UIKit
import struct PopcornKit.Subtitle

class ExtendedSubtitleViewController: UIViewController {
    
    var allSubtitles = Dictionary<String, [Subtitle]>()
    var currentSubtitle:Subtitle?
    var delegate:SubtitlesViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }


    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showExtendedTableView"{
            if let destination = segue.destination as? ExtendedSubtitleSelectionTableViewController{
                destination.allSubtitles = self.allSubtitles
                destination.currentSubtitle = self.currentSubtitle
                destination.delegate = self.delegate
            }
        }
    }


}
