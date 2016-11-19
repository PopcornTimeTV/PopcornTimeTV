

import UIKit
import SwiftyTimer

protocol UpNextViewDelegate: class {
    func constraintsWereUpdated(willHide hide: Bool)
    func timerFinished()
}

class UpNextView: UIVisualEffectView {
    
    @IBOutlet var nextEpisodeInfoLabel: UILabel!
    @IBOutlet var nextEpisodeTitleLabel: UILabel!
    @IBOutlet var nextShowTitleLabel: UILabel!
    @IBOutlet var nextEpisodeThumbImageView: UIImageView!
    @IBOutlet var nextEpisodeCountdownLabel: UILabel!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    @IBOutlet var trailingConstraint: NSLayoutConstraint!
    
    weak var delegate: UpNextViewDelegate?
    fileprivate var timer: Timer!
    fileprivate var updateTimer: Timer!
    
    func show() {
        if isHidden {
            isHidden = false
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
            delegate?.constraintsWereUpdated(willHide: false)
            startTimer()
        }
    }
    
    func hide() {
        if !isHidden {
            trailingConstraint.isActive = true
            leadingConstraint.isActive = false
            delegate?.constraintsWereUpdated(willHide: true)
        }
    }
    
    func startTimer() {
        var delay = 10
        updateTimer = Timer.every(1.0) {
            if delay - 1 >= 0 {
                delay -= 1
                self.nextEpisodeCountdownLabel.text = String(delay)
            }
        }
        timer = Timer.after(10.0, {
            self.updateTimer.invalidate()
            self.updateTimer = nil
            self.delegate?.timerFinished()
        })
    }
    
    @IBAction func closePlayNextView() {
        hide()
        timer.invalidate()
        timer = nil
    }
    @IBAction func playNextNow() {
        hide()
        updateTimer.invalidate()
        updateTimer = nil
        timer.invalidate()
        timer = nil
        delegate?.timerFinished()
    }

}

extension PCTPlayerViewController {
    func constraintsWereUpdated(willHide hide: Bool) {
        UIView.animate(withDuration: animationLength, delay: 0, options: UIViewAnimationOptions(), animations: { 
            self.view.layoutIfNeeded()
            }, completion: { _ in
                if hide {
                   self.upNextView.isHidden = true
                }
        })
    }
    
    func timerFinished() {
        didFinishPlaying()
        delegate?.playNext(nextEpisode!)
    }
}
