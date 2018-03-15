

import Foundation
import UIKit

extension PCTPlayerViewController: UIPopoverPresentationControllerDelegate, GoogleCastTableViewControllerDelegate, UIViewControllerTransitioningDelegate {
    
    override var prefersStatusBarHidden: Bool {
        return !shouldHideStatusBar
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return !shouldHideStatusBar
    }
    
    @objc func volumeChanged(forSlider: UISlider?) {
        if overlayViews.first!.isHidden {
            toggleControlsVisible()
        }
        if let slider = forSlider as UISlider? {
            switch(slider.value){
            case _ where slider.value == 0:
                volumeButton?.setImage(#imageLiteral(resourceName: "Volume Minimum"), for: .normal)
            case _ where slider.value <= 0.4:
                volumeButton?.setImage(#imageLiteral(resourceName: "Volume Maximum"), for: .normal)
                volumeButton?.imageView?.frame.origin.x = 11
            case _ where slider.value <= 0.7:
                volumeButton?.imageView?.frame.origin.x = 6
            default:
                volumeButton?.imageView?.frame.origin.x = 0
            }
        }
    }
    
    @IBAction func volumeSingleTap(){
        for subview in volumeView.subviews {
            if let slider = subview as? UISlider {
                if(slider.value == 0.0){
                    slider.setValue(Float(previousVolumeValue), animated: true)
                }else{
                    previousVolumeValue = Double(slider.value)
                    slider.setValue(0.0, animated: true)
                }
                
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
            mediaplayer.videoCropGeometry = UIScreen.screens.count > 1 ? UnsafeMutablePointer<Int8>(mutating: (UIScreen.screens[1].aspectRatio as NSString).utf8String) : UnsafeMutablePointer<Int8>(mutating: (UIScreen.main.aspectRatio as NSString).utf8String) 
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
