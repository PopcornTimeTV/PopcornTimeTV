

import Foundation
import AVFoundation

class AudioManager: NSObject, AVAudioPlayerDelegate {
    var player: AVAudioPlayer?
    var currentPlayingThemeId: Int?
    
    static let shared: AudioManager = AudioManager()

    func playTheme(_ id: Int) {
        if self.currentPlayingThemeId == id { return }
        if let player = player, player.isPlaying { player.stop() }

        URLSession.shared.dataTask(with: URL(string: "http://tvthemes.plexapp.com/\(id).mp3")!, completionHandler: { (data, response, error) in
            do {
                if let data = data {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    try AVAudioSession.sharedInstance().setActive(true)

                    let volume = UserDefaults.standard.float(forKey: "TVShowVolume") 
                    
                    self.player = try AVAudioPlayer(data: data)
                    self.player!.volume = volume
                    self.player!.delegate = self
                    self.player!.prepareToPlay()
                    self.player!.play()
                    self.currentPlayingThemeId = id
                }
            } catch let error {
                print(error)
            }
        }).resume()
    }

    func stopTheme() {
        self.player?.stop()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.currentPlayingThemeId = nil
        self.player = nil
    }
}
