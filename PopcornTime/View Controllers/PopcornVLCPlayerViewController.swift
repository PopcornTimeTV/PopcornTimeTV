//
//  PopcornVLCPlayerViewController.swift
//  PopcornTime
//
//  Created by Tomi De Lucca on 4/15/16.
//  Copyright © 2016 PopcornTime. All rights reserved.
//

import PopcornTorrent
import TVMLKitchen

class PopcornVLCPlayerViewController: VLCPlayerViewController {

    override func destroyViewController() {
       PTTorrentStreamer.sharedStreamer().cancelStreaming()
       Kitchen.appController.navigationController.popViewControllerAnimated(true)
    }

}
