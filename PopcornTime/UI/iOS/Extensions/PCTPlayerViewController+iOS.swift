

import Foundation
import UIKit

extension PCTPlayerViewController: UIPopoverPresentationControllerDelegate, GoogleCastTableViewControllerDelegate, UIViewControllerTransitioningDelegate {
    
    
    override var prefersStatusBarHidden: Bool {
        return !shouldHideStatusBar
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func volumeChanged() {
        if overlayViews.first!.isHidden {
            toggleControlsVisible()
        }
//        if let slider = volumeView.subviews.flatMap({$0 as? UISlider}).first {
//            volumeSlider.setValue(slider.value, animated: true)
//        }
    }
    
    @IBAction func volumeSingleTap(){
        for subview in volumeView.subviews {
            if let slider = subview as? UISlider {
                slider.setValue(0.0, animated: true)
            }
        }
    }
    
    @IBAction func volumeLongTap(){
        showVolumeConstraint?.priority = UILayoutPriority(rawValue: 999)
        UIView.animate(withDuration: .default) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func sliderDidDrag() {
        resetIdleTimer()
    }
    
    @IBAction func scrubbingChanged() {
        var text = ""
        switch progressBar.progressSlider.scrubbingSpeed {
        case 1.0:
            text = "Hi-Speed".localized
        case 0.5:
            text = "Half-Speed".localized
        case 0.25:
            text = "Quarter-Speed".localized
        case 0.1:
            text = "Fine".localized
        default:
            break
        }
        text += " " + "Scrubbing".localized
        scrubbingSpeedLabel!.text = text
        positionSliderDidDrag()
    }
    
    @IBAction func scrubbingBegan() {
        screenshotImageView!.image = nil
        screenshotImageView!.isHidden = false
        
        if mediaplayer.isPlaying {
            mediaplayer.pause()
        }
        
        UIView.animate(withDuration: .default, animations: {
            self.tooltipView?.isHidden = false
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func volumeSliderAction() {
        resetIdleTimer()
//        for subview in volumeView.subviews {
//            if let slider = subview as? UISlider {
//                slider.setValue(volumeSlider.value, animated: true)
//            }
//        }
    }
    
    @IBAction func scrubbingEnded() {
        positionSliderAction()
        
        screenshotImageView!.image = nil
        screenshotImageView!.isHidden = true
        
        
        view.layoutIfNeeded()
        UIView.animate(withDuration: .default, animations: {
            self.tooltipView?.isHidden = true
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func switchVideoDimensions() {
        resetIdleTimer()
        if mediaplayer.videoCropGeometry == nil // Change to aspect to scale to fill
        {
            mediaplayer.videoCropGeometry = UnsafeMutablePointer<Int8>(mutating: (UIScreen.main.aspectRatio as NSString).utf8String)
            videoDimensionsButton!.setImage(UIImage(named: "Scale To Fit"), for: .normal)
            screenshotImageView!.contentMode = .scaleAspectFill
        } else // Change aspect ratio to scale to fit
        {
            videoDimensionsButton!.setImage(UIImage(named: "Scale To Fill"), for: .normal)
            mediaplayer.videoAspectRatio = nil
            mediaplayer.videoCropGeometry = nil
            screenshotImageView!.contentMode = .scaleAspectFit
        }
    }
    
    // MARK: - GoogleCastTableViewControllerDelegate
    
    func didConnectToDevice() {
        mediaplayer.delegate = nil
        mediaplayer.stop()
        delegate?.playerViewControllerPresentCastPlayer(self)
    }
    
    // MARK: - Navigation
    
    override func performSegue(withIdentifier identifier: String, sender: Any?) {
        guard let container = upNextContainerView, identifier == "showUpNext" else { return super.performSegue(withIdentifier: identifier, sender: sender) }
        
        UIView.animate(withDuration: .default) {
            container.transform = CGAffineTransform(translationX: container.frame.size.width, y: 0)
        }
    }
}
