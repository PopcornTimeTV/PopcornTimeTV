

import Foundation

// MARK: Transitioning Delegate
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
        
        if sender.direction == .down {
            presentOptionsViewController()
            handleOptionsGesture(sender)
            return
        }
        
        let translation = sender.translation(in: view)
        let offset = progressBar.progress + (translation.x - lastTranslation)/progressBar.bounds.width/8.0
        
        switch sender.state {
        case .cancelled:
            fallthrough
        case .ended:
            positionSliderAction()
            mediaplayer.play()
            lastTranslation = 0.0
            progressBar.isScrubbing = false
        case .began:
            progressBar.isHidden ? toggleControlsVisible() : ()
            progressBar.hint = .scanForward
            mediaplayer.isPlaying ? mediaplayer.pause() : ()
            progressBar.isScrubbing = true
            resetIdleTimer()
            fallthrough
        case .changed:
            progressBar.progress = offset
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
}

