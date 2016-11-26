

import Foundation

extension PCTPlayerViewController: UIViewControllerTransitioningDelegate, OptionsViewControllerDelegate {
    
    func didSelectSize(_ size: Float) {
        (mediaplayer as VLCFontAppearance).setTextRendererFontSize!(NSNumber(value: size))
    }
    
    func didSelectEncoding(_ encoding: String) {
        mediaplayer.media.addOptions([vlcSettingTextEncoding: encoding])
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presented is OptionsViewController ? OptionsAnimatedTransitioning(isPresenting: true) : nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissed is OptionsViewController ? OptionsAnimatedTransitioning(isPresenting: false) : nil
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return presented is OptionsViewController ? OptionsPresentationController(presentedViewController: presented, presenting: presenting) : nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return animator is OptionsAnimatedTransitioning && interactor.hasStarted ? interactor : nil
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return animator is OptionsAnimatedTransitioning && interactor.hasStarted ? interactor : nil
    }
    
    func handleOptionsGesture(_ sender: UIPanGestureRecognizer) {
        let percentThreshold: CGFloat = 0.4
        let superview = sender.view!.superview!
        let translation = sender.translation(in: superview)
        let progress = translation.y/superview.bounds.height
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
        case .ended:
            interactor.hasStarted = false
            interactor.shouldFinish ? interactor.finish() : interactor.cancel()
        default:
            break
        }
    }
    
    @IBAction func handlePositionSliderGesture(_ sender: UIPanGestureRecognizer) {
        guard !progressBar.isHidden && !mediaplayer.isPlaying else { return }
        
        let translation = sender.translation(in: view)
        
        if translation.y > 200.0 && !progressBar.isScrubbing {
            presentOptionsViewController()
            handleOptionsGesture(sender)
            return
        }
        
        let offset = progressBar.scrubbingProgress + (translation.x - lastTranslation)/progressBar.bounds.width/8.0
        
        switch sender.state {
        case .cancelled:
            fallthrough
        case .ended:
            lastTranslation = 0.0
        case .began:
            progressBar.isScrubbing = true
            fallthrough
        case .changed:
            progressBar.scrubbingProgress = offset
            positionSliderDidDrag()
            lastTranslation = translation.x
        default:
            return
        }
    }
    
    func presentOptionsViewController() {
        if presentedViewController is OptionsViewController { return }
        let destinationController = storyboard?.instantiateViewController(withIdentifier: "OptionsViewController") as! OptionsViewController
        destinationController.transitioningDelegate = self
        destinationController.modalPresentationStyle = .custom
        destinationController.interactor = interactor
        present(destinationController, animated: true, completion: nil)
        destinationController.subtitlesViewController.subtitles = subtitles
        destinationController.subtitlesViewController.currentSubtitle = currentSubtitle
        destinationController.subtitlesViewController.delegate = self
        destinationController.infoViewController.media = media
    }
    
    func touchLocationDidChange(_ gesture: VLCSiriRemoteGestureRecognizer) {
        progressBar.hint = .none
        resetIdleTimer()
        guard !progressBar.isScrubbing && mediaplayer.isPlaying && !progressBar.isHidden && !progressBar.isBuffering else { return }
        switch gesture.touchLocation {
        case .left:
            progressBar.hint = .jumpBackward10
            if gesture.isClick { rewind(); progressBar.hint = .none }
        case .right:
            progressBar.hint = .jumpForward10
            if gesture.isClick { fastForward(); progressBar.hint = .none }
        default: return
        }
    }
    
    func clickGesture(_ gesture: VLCSiriRemoteGestureRecognizer) {
        guard gesture.isClick, progressBar.hint == .none else {
            progressBar.isHidden ? toggleControlsVisible() : ()
            return
        }
        
        guard !progressBar.isScrubbing else {
            endScrubbing()
            if mediaplayer.isSeekable {
                let time = NSNumber(value: Float(progressBar.scrubbingProgress * streamDuration))
                mediaplayer.time = VLCTime(number: time)
                // Force a progress change rather than waiting for VLCKit's delegate call to.
                progressBar.progress = progressBar.scrubbingProgress
                progressBar.elapsedTimeLabel.text = progressBar.scrubbingTimeLabel.text
            }
            return
        }
        
        mediaplayer.canPause ? mediaplayer.pause() : ()
        progressBar.isHidden ? toggleControlsVisible() : ()
        dimmerView.isHidden = false
        progressBar.isScrubbing = true
        
        let currentTime = NSNumber(value: Float(progressBar.progress * streamDuration))
        if let image = screenshotAtTime(currentTime) {
            progressBar.screenshot = image
        }
    }
    
    @IBAction func menuPressed() {
        progressBar.isScrubbing ? endScrubbing() : didFinishPlaying()
    }
    
    func endScrubbing() {
        mediaplayer.willPlay ? mediaplayer.play() : ()
        !progressBar.isHidden ? toggleControlsVisible() : ()
        progressBar.isScrubbing = false
        dimmerView.isHidden = true
    }
}

