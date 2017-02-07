

import Foundation
import UIKit
import PopcornKit

extension PCTPlayerViewController: UIPopoverPresentationControllerDelegate {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.popoverPresentationController?.delegate = self
        if segue.identifier == "showSubtitles", let vc = (segue.destination as? UINavigationController)?.viewControllers.first as? OptionsTableViewController {
            vc.subtitles = subtitles
            vc.currentSubtitle = currentSubtitle
            vc.currentSubtitleDelay = mediaplayer.currentVideoSubTitleDelay/Int(1e6)
            vc.currentAudioDelay = mediaplayer.currentAudioPlaybackDelay/Int(1e6)
            vc.delegate = self
        } else if segue.identifier == "showDevices" {
            let vc = (segue.destination as! UINavigationController).viewControllers.first! as! StreamToDevicesTableViewController
            vc.castMetadata = (title: media.title, image: media.smallCoverImage != nil ? URL(string: media.smallCoverImage!) : nil, contentType: media is Movie ? "video/mp4" : "video/x-matroska", subtitles: media.subtitles, url: url.relativeString, mediaAssetsPath: directory)
        }
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        (controller.presentedViewController as! UINavigationController).topViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonPressed))
        return controller.presentedViewController
    }
    
    
    func cancelButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return !shouldHideStatusBar
    }
    
    func volumeChanged() {
        if overlayViews.first!.isHidden {
            toggleControlsVisible()
        }
        for subview in volumeView.subviews {
            if let slider = subview as? UISlider {
                volumeSlider.setValue(slider.value, animated: true)
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        for constraint in compactConstraints {
            constraint.priority = traitCollection.horizontalSizeClass == .compact ? 999 : 240
        }
        for constraint in regularConstraints {
            constraint.priority = traitCollection.horizontalSizeClass == .compact ? 240 : 999
        }
        UIView.animate(withDuration: animationLength, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func sliderDidDrag() {
        resetIdleTimer()
    }
    
    @IBAction func scrubbingChanged() {
        var text = ""
        switch progressBar.progressSlider.scrubbingSpeed {
        case 1.0:
            text = "Hi-Speed"
        case 0.5:
            text = "Half-Speed"
        case 0.25:
            text = "Quarter-Speed"
        case 0.1:
            text = "Fine"
        default:
            break
        }
        text += " Scrubbing"
        scrubbingSpeedLabel!.text = text
        positionSliderDidDrag()
    }
    
    @IBAction func scrubbingBegan() {
        screenshotImageView!.image = nil
        screenshotImageView!.isHidden = false
        
        if mediaplayer.isPlaying {
            mediaplayer.pause()
        }
        
        UIView.animate(withDuration: animationLength, animations: {
            self.finishedScrubbingConstraints!.isActive = false
            self.duringScrubbingConstraints!.isActive = true
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func volumeSliderAction() {
        resetIdleTimer()
        for subview in volumeView.subviews {
            if let slider = subview as? UISlider {
                slider.setValue(volumeSlider.value, animated: true)
            }
        }
    }
    
    @IBAction func scrubbingEnded() {
        positionSliderAction()
        
        screenshotImageView!.image = nil
        screenshotImageView!.isHidden = true
        
        
        view.layoutIfNeeded()
        UIView.animate(withDuration: animationLength, animations: {
            self.duringScrubbingConstraints!.isActive = false
            self.finishedScrubbingConstraints!.isActive = true
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
}


