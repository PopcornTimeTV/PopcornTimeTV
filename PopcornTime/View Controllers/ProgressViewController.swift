//
//  ProgressViewController.swift
//  PopcornTime
//
//  Created by Yogi Bear on 3/18/16.
//  Copyright © 2016 PopcornTime. All rights reserved.
//

import UIKit
import PopcornTorrent
import AVKit
import TVMLKitchen
import Kingfisher

class ProgressViewController: UIViewController {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var statsLabel: UILabel!

    var magnet: String!
    var imdbId: String!
    var imageAddress: String!
    var backgroundImageAddress: String!
    var movieName: String!
    var shortDescription: String!

    var episodeName: String!
    var episodeSeason: Int!
    var episodeNumber: Int!

    var cachedSubtitles: [AnyObject]!

    var downloading = false
    var streaming = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if !self.imdbId.containsString("tt") {
            self.imdbId = nil
        }

        SubtitleManager.sharedManager().search(self.episodeName, episodeSeason: self.episodeSeason, episodeNumber: self.episodeNumber, imdbId: self.imdbId) { subtitles in
            self.cachedSubtitles = subtitles
        }

        if let _ = magnet, let _ = movieName, let _ = imageAddress, let _ = backgroundImageAddress {
            statsLabel.text = ""
            percentLabel.text = "0%"
            nameLabel.text = "Processing " + movieName + "..."
            imageView.kf_setImageWithURL(NSURL(string: imageAddress)!)
            backgroundImageView.kf_setImageWithURL(NSURL(string: backgroundImageAddress)!)

            if downloading {
                return
            }

            PTTorrentStreamer.sharedStreamer().startStreamingFromFileOrMagnetLink(magnet, progress: { status in
                self.downloading = true

                self.percentLabel.text = "\(Int(status.bufferingProgress * 100))%"

                let speedString = NSByteCountFormatter.stringFromByteCount(Int64(status.downloadSpeed), countStyle: .Binary)
                self.statsLabel.text = "Speed: \(speedString)/s  Seeds: \(status.seeds)  Peers: \(status.peers)  Overall Progress: \(Int(status.totalProgreess*100))%"

                if let subs = self.cachedSubtitles {
                    self.statsLabel.text! += "  \(subs.count) " + (subs.count == 1 ? "Subtitle Found" : "Subtitles Found")
                }

                self.progressView.progress = status.bufferingProgress
                if self.progressView.progress > 0.0 {
                    self.nameLabel.text = "Buffering " + self.movieName + "..."
                }

                print("\(Int(status.bufferingProgress*100))%, \(Int(status.totalProgreess*100))%, \(speedString)/s, Seeds: \(status.seeds), Peers: \(status.peers)")
            }, readyToPlay: { url in
                self.playVLCVideo(url)
            }) { error in
                print(error)
            }
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        if !self.streaming {
            PTTorrentStreamer.sharedStreamer().cancelStreaming()
            SubtitleManager.sharedManager().cleanSubs()
        }
    }

    func playVLCVideo(url: NSURL) {
        AudioManager.sharedManager().stopTheme()

        Kitchen.appController.navigationController.popViewControllerAnimated(false)
        let playerViewController = SYVLCPlayerViewController(URL: url, imdbID: "", subtitles: cachedSubtitles)
        Kitchen.appController.navigationController.pushViewController(playerViewController, animated: true)
        self.streaming = true
    }

}
