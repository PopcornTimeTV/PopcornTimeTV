

import Foundation
import AVFoundation

class AudioManager: NSObject, AVAudioPlayerDelegate {

    var player: AVAudioPlayer!
    var currentPlayingThemeId: Int!

    class func sharedManager() -> AudioManager {
        struct Struct {
            static let Instance = AudioManager()
        }

        return Struct.Instance
    }

    override init() {
        super.init()
    }

    func playTheme(id: Int) {
        if let _ = self.currentPlayingThemeId {
            if self.currentPlayingThemeId == id {
                return
            }
        }

        if let _ = self.player {
            if self.player.playing {
                self.player.stop()
            }
        }

        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://tvthemes.plexapp.com/\(id).mp3")!) { (data, response, error) in
            do {
                if let data = data {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    try AVAudioSession.sharedInstance().setActive(true)

                    self.player = try AVAudioPlayer(data: data)
                    self.player.volume = NSUserDefaults.standardUserDefaults().floatForKey("TVShowVolume") ?? 0.75
                    self.player.delegate = self
                    self.player.prepareToPlay()
                    self.player.play()
                }
            } catch let error {
                print(error)
            }
        }.resume()
    }

    func stopTheme() {
        if let _ = self.player {
            self.player.stop()
        }
    }

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        self.currentPlayingThemeId = nil
    }

}
