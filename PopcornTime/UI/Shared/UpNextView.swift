

import UIKit
import SwiftyTimer
#if os(tvOS)
    import MBCircularProgressBar
#endif

protocol UpNextViewDelegate: class {
    func constraintsWereUpdated(willHide hide: Bool)
    func timerFinished()
}

class UpNextView: UIVisualEffectView {
    
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var expandedConstraint: NSLayoutConstraint!
    @IBOutlet var hiddenConstraint: NSLayoutConstraint!
    @IBOutlet var watchNowButton: UIButton!
    
    weak var delegate: UpNextViewDelegate?
    fileprivate var timer: Timer?
    fileprivate var updateTimer: Timer?
    
    #if os(iOS)
    @IBOutlet var countdownLabel: UILabel!
    #elseif os(tvOS)
    @IBOutlet var countdownView: MBCircularProgressBarView!
    #endif
    
    var viewToFocus: UIView? = nil {
        didSet {
            guard viewToFocus != nil else { return }
            setNeedsFocusUpdate()
            updateFocusIfNeeded()
        }
    }
    
    override var preferredFocusedView: UIView? {
        return viewToFocus != nil ? viewToFocus : super.preferredFocusedView
    }
    
    func show() {
        guard isHidden else { return }
        isHidden = false
        hiddenConstraint.priority = 250
        expandedConstraint.priority = 999
        delegate?.constraintsWereUpdated(willHide: false)
        startTimer()
        viewToFocus = watchNowButton
    }
    
    func hide() {
        guard !isHidden else { return }
        hiddenConstraint.priority = 999
        expandedConstraint.priority = 250
        delegate?.constraintsWereUpdated(willHide: true)
    }
    
    func startTimer() {
        var delay = 30
        updateTimer = Timer.every(1.0) {
            if delay - 1 >= 0 {
                delay -= 1
                #if os(iOS)
                    self.countdownLabel.text = String(delay)
                #elseif os(tvOS)
                    self.countdownView.value = CGFloat(delay)
                #endif
            }
        }
        timer = Timer.after(30.0, {
            self.updateTimer?.invalidate()
            self.updateTimer = nil
            self.delegate?.timerFinished()
        })
    }
    
    @IBAction func cancel() {
        hide()
        timer?.invalidate()
        timer = nil
    }
    
    @IBAction func watchNow() {
        hide()
        updateTimer?.invalidate()
        updateTimer = nil
        timer?.invalidate()
        timer = nil
        delegate?.timerFinished()
    }

}
