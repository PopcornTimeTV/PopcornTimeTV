

import Foundation
import AVFoundation
import Alamofire
import SwiftyJSON

/// Class for managing TV Show and Movie Theme songs.
public class ThemeSongManager: NSObject, AVAudioPlayerDelegate {
    
    /// Global player ref.
    private var player: AVAudioPlayer!
    
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
                    
                    self.player = try AVAudioPlayer(data: data)
                    self.player.volume = 0
                    self.player.numberOfLoops = NSNotFound
                    self.player.delegate = self
                    self.player.prepareToPlay()
                    self.player.play()
                    self.fadeTo(volume: UserDefaults.standard.float(forKey: "themeSongVolume"))
                }
            } catch let error {
                print(error)
            }
        })
        task?.resume()
    }
    
    /**
     Fades player volume to specified volume in specified amount of seconds (defaults to 3.0) if available. Devices under 10.0 will just go straight to specified volume.
     
     - Parameter volume:    Volume to fade to.
     - Parameter duration:  The total time the song will fade out for. Defaults to 3 seconds.
     */
    private func fadeTo(volume: Float, duration: TimeInterval = 3.0) {
        if #available(tvOS 10.0, iOS 10.0, *) {
            self.player?.setVolume(volume, fadeDuration: duration)
        } else {
            self.player?.volume = volume
        }
    }
    
    /// Stops playing theme music, if previously playing.
    public func stopTheme() {
        fadeTo(volume: 0, duration: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.player?.stop()
            self.task?.cancel()
            self.task = nil
        }
    }
}

