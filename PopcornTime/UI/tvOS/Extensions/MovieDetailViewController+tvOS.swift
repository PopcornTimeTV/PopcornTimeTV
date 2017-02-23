

import Foundation
import AVKit
import XCDYouTubeKit

extension MovieDetailViewController {
    
    @IBAction func playTrailer() {
        let playerController = AVPlayerViewController()
        present(playerController, animated: true)
        XCDYouTubeClient.default().getVideoWithIdentifier(movie.trailerCode!) { (video, error) in
            guard let streamUrls = video?.streamURLs,
                let qualities = Array(streamUrls.keys) as? [UInt] else { return }
            let preferredVideoQualities = [XCDYouTubeVideoQuality.HD720.rawValue, XCDYouTubeVideoQuality.medium360.rawValue, XCDYouTubeVideoQuality.small240.rawValue]
            var videoUrl: URL?
            forLoop: for quality in preferredVideoQualities {
                if let index = qualities.index(of: quality) {
                    videoUrl = Array(streamUrls.values)[index]
                    break forLoop
                }
            }
            guard let url = videoUrl else {
                self.dismiss(animated: true)
                
                let vc = UIAlertController(title: "Oops!", message: "Error fetching valid trailer URL from Youtube.", preferredStyle: .alert)
                
                vc.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                self.present(vc, animated: true)
                
                return
            }
            
            playerController.player = AVPlayer(url: url)
            playerController.player!.play()
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }
    
    func playerDidFinishPlaying() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        dismiss(animated: true)
    }
}
