

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

    func playTheme(_ id: Int) {
        if let _ = self.currentPlayingThemeId {
            if self.currentPlayingThemeId == id {
                return
            }
        }

        if let _ = self.player {
            if self.player.isPlaying {
                self.player.stop()
            }
        }

        URLSession.shared.dataTask(with: URL(string: "http://tvthemes.plexapp.com/\(id).mp3")!, completionHandler: { (data, response, error) in
            do {
                if let data = data {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    try AVAudioSession.sharedInstance().setActive(true)

                    self.player = try AVAudioPlayer(data: data)
                    self.player.volume = UserDefaults.standard.float(forKey: "TVShowVolume") ?? 0.75
                    self.player.delegate = self
                    self.player.prepareToPlay()
                    self.player.play()
                }
            } catch let error {
                print(error)
            }
        }) .resume()
    }

    func stopTheme() {
        if let _ = self.player {
            self.player.stop()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.currentPlayingThemeId = nil
    }

}
