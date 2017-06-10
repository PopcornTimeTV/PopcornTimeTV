

import Foundation
import AVFoundation
import Alamofire
import SwiftyJSON

/// Class for managing TV Show and Movie Theme songs.
public class ThemeSongManager: NSObject, AVAudioPlayerDelegate {
    
    /// Global player ref.
    private var player: AVAudioPlayer?
    
    /// Global download task ref.
    private var task: URLSessionTask?
    
    /// Creates new instance of ThemeSongManager class
    public static let shared: ThemeSongManager = ThemeSongManager()
    
    /**
     Starts playing TV Show theme music.
     
     - Parameter id: TVDB id of the show.
     */
    public func playShowTheme(_ id: Int) {
        playTheme("http://tvthemes.plexapp.com/\(id).mp3")
    }
    
    /**
     Starts playing Movie theme music.
     
     - Parameter name: The name of the movie.
     */
    public func playMovieTheme(_ name: String) {
        Alamofire.request("https://itunes.apple.com/search", parameters: ["term": "\(name) soundtrack", "media": "music", "attribute": "albumTerm", "limit": 1]).validate().responseJSON { (response) in
            guard let response = response.result.value else { return }
            let responseDict = JSON(response)
            if let url = responseDict["results"].arrayValue.first?["previewUrl"].string { self.playTheme(url) }
        }
    }
    
    /**
     Starts playing theme music from URL.
     
     - Parameter url: Valid url pointing to a track.
     */
    private func playTheme(_ url: String) {
        if let player = player, player.isPlaying { player.stop() }
        
        self.task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { (data, response, error) in
            do {
                if let data = data {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    
                    let player = try AVAudioPlayer(data: data)
                    player.volume = 0
                    player.numberOfLoops = NSNotFound
                    player.delegate = self
                    player.prepareToPlay()
                    player.play()
                    
                    let adjustedVolume = UserDefaults.standard.float(forKey: "themeSongVolume") * 0.25
                    player.setVolume(adjustedVolume, fadeDuration: 3.0)
                    
                    self.player = player
                }
            } catch let error {
                print(error)
            }
        })
        task?.resume()
    }
    
    /// Stops playing theme music, if previously playing.
    public func stopTheme() {
        let delay = 1.0
        player?.setVolume(0, fadeDuration: delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.player?.stop()
            self.task?.cancel()
            self.task = nil
        }
    }
}

