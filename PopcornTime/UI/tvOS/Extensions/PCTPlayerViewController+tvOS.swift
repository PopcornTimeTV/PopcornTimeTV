

import Foundation

extension PCTPlayerViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presented is OptionsViewController ? OptionsAnimatedTransitioning(isPresenting: true) : nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissed is OptionsViewController ? OptionsAnimatedTransitioning(isPresenting: false) : nil
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return presented is OptionsViewController ? OptionsPresentationController(presentedViewController: presented, presenting: presenting) : nil
    }
    
    @IBAction func handlePositionSliderGesture(_ sender: UIPanGestureRecognizer) {
        
        let translation = sender.translation(in: view)
        
        guard !(presentedViewController is OptionsViewController) && progressBar.isScrubbing && !progressBar.isHidden else { return }
        
        let offset = progressBar.scrubbingProgress + Float((translation.x - lastTranslation)/progressBar.bounds.width/8.0)
        
        switch sender.state {
        case .cancelled:
            fallthrough
        case .ended:
            lastTranslation = 0.0
        case .began:
            fallthrough
        case .changed:
            progressBar.scrubbingProgress = offset
            positionSliderDidDrag()
            lastTranslation = translation.x
        default:
            return
        }
    }
    
    @IBAction func presentOptionsViewController() {
        if presentedViewController is OptionsViewController || !upNextView.isHidden { return }
        let destinationController = storyboard?.instantiateViewController(withIdentifier: "OptionsViewController") as! OptionsViewController
        destinationController.transitioningDelegate = self
        destinationController.modalPresentationStyle = .custom
        destinationController.delegate = self
        present(destinationController, animated: true)
        destinationController.subtitlesViewController.subtitles = subtitles
        destinationController.subtitlesViewController.currentSubtitle = currentSubtitle
        destinationController.subtitlesViewController.currentDelay = mediaplayer.currentVideoSubTitleDelay/Int(1e6)
        destinationController.audioViewController.currentDelay = mediaplayer.currentAudioPlaybackDelay/Int(1e6)
        destinationController.infoViewController.media = media
    }
    
    func touchLocationDidChange(_ gesture: SiriRemoteGestureRecognizer) {
        if gesture.state == .ended { hideInfoLabel() } else if gesture.isLongTap { showInfoLabel() }
        
        progressBar.hint = .none
        resetIdleTimer()
        
        guard !progressBar.isScrubbing && mediaplayer.isPlaying && !progressBar.isHidden && !progressBar.isBuffering else { return }
        
        switch gesture.touchLocation {
        case .left:
            if gesture.isClick && gesture.state == .ended { rewind(); progressBar.hint = .none }
            if gesture.isLongPress { rewindHeld(gesture) } else if gesture.state != .ended { progressBar.hint = .jumpBackward30 }
        case .right:
            if gesture.isClick && gesture.state == .ended { fastForward(); progressBar.hint = .none }
            if gesture.isLongPress { fastForwardHeld(gesture) } else if gesture.state != .ended { progressBar.hint = .jumpForward30 }
        default: return
        }
    }
    
    func clickGesture(_ gesture: SiriRemoteGestureRecognizer) {
        guard gesture.touchLocation == .unknown && gesture.isClick && gesture.state == .ended && upNextView.isHidden else {
            progressBar.isHidden ? toggleControlsVisible() : ()
            return
        }
        
        guard !progressBar.isScrubbing else {
            endScrubbing()
            if mediaplayer.isSeekable {
                let time = NSNumber(value: progressBar.scrubbingProgress * streamDuration)
                mediaplayer.time = VLCTime(number: time)
                // Force a progress change rather than waiting for VLCKit's delegate call to.
                progressBar.progress = progressBar.scrubbingProgress
                progressBar.elapsedTimeLabel.text = progressBar.scrubbingTimeLabel.text
            }
            return
        }
        
        mediaplayer.canPause ? mediaplayer.pause() : ()
        progressBar.isHidden ? toggleControlsVisible() : ()
        dimmerView!.isHidden = false
        progressBar.isScrubbing = true
        
        let currentTime = NSNumber(value: progressBar.progress * streamDuration)
        if let image = screenshotAtTime(currentTime) {
            progressBar.screenshot = image
        }
    }
    
    @IBAction func menuPressed() {
        guard upNextView.isHidden else {
            upNextView.hide()
            return
        }
        progressBar.isScrubbing ? endScrubbing() : didFinishPlaying()
    }
    
    func endScrubbing() {
        mediaplayer.willPlay ? mediaplayer.play() : ()
        resetIdleTimer()
        progressBar.isScrubbing = false
        dimmerView!.isHidden = true
    }
    
    func hideInfoLabel() {
        guard infoHelperView!.alpha == 1 else { return }
        UIView.animate(withDuration: 0.3) {
            self.infoHelperView!.alpha = 0.0
        }
    }
    
    func showInfoLabel() {
        guard infoHelperView!.alpha == 0 else { return }
        UIView.animate(withDuration: 0.3) {
            self.infoHelperView!.alpha = 1.0
        }
    }
    
    func alertFocusDidChange(_ notification: Notification) {
        guard let alertController = notification.object as? UIAlertController,
            let UIAlertControllerActionView = NSClassFromString("_UIAlertControllerActionView"),
            let dimmerView = alertController.value(forKey: "_dimmingView") as? UIView else { return }
        
        dimmerView.isHidden = true
        progressBar.isBuffering = false
        
        let subviews = alertController.view.recursiveSubviews.filter({type(of: $0) == UIAlertControllerActionView})
        
        for view in subviews {
            guard let title = view.value(forKeyPath: "label.text") as? String,
                let isHighlighted = view.value(forKey: "isHighlighted") as? Bool,
                isHighlighted else { continue }
            
            if title == "Resume Playing".localized {
                progressBar.progress = startPosition
            } else if title == "Start from Begining".localized {
                progressBar.progress = 0
            }
            
            positionSliderDidDrag()
            
            workItem?.cancel() // Cancel item so screenshot is not loaded
            progressBar.elapsedTimeLabel.text = progressBar.scrubbingTimeLabel.text
            
            progressBar.setNeedsLayout()
            progressBar.layoutIfNeeded()
        }
    }
    
    func didSelectEqualizerProfile(_ profile: EqualizerProfiles) {
        mediaplayer.resetEqualizer(fromProfile: profile.rawValue)
        mediaplayer.equalizerEnabled = true
    }
}

