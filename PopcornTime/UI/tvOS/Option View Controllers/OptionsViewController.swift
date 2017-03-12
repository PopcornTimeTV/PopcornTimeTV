

import UIKit
import PopcornKit

protocol OptionsViewControllerDelegate: class {
    func didSelectSubtitle(_ subtitle: Subtitle?)
    func didSelectSubtitleDelay(_ delay: Int)
    func didSelectEncoding(_ encoding: String)
    func didSelectAudioDelay(_ delay: Int)
}


class OptionsViewController: UIViewController, UIGestureRecognizerDelegate, UITabBarDelegate {
    
    weak var delegate: OptionsViewControllerDelegate?

    @IBOutlet var infoContentView: UIView!
    @IBOutlet var subtitlesContentView: UIView!
    @IBOutlet var audioContentView: UIView!

    @IBOutlet var tabBar: UITabBar!
    @IBOutlet var swipeGesture: UISwipeGestureRecognizer!

    var infoViewController: InfoViewController!
    var subtitlesViewController: SubtitlesViewController!
    var audioViewController: AudioViewController!

    @IBAction func dismissOptionsViewController() {
        dismiss(animated: true)
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let index = tabBar.items!.index(of: item)!
        switch index {
        case 0:
            subtitlesContentView.isHidden = true
            audioContentView.isHidden = true
            infoContentView.isHidden = false
        case 1:
            subtitlesContentView.isHidden = false
            audioContentView.isHidden = true
            infoContentView.isHidden = true
        case 2:
            subtitlesContentView.isHidden = true
            audioContentView.isHidden = false
            infoContentView.isHidden = true
        default:
            break
        }
    }
    
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == swipeGesture, let focused = tabBar.subviews.first(where: {$0 is UIScrollView})?.subviews.contains(where: { $0.isFocused }) // If gesture is pan gesture and one of the buttons is focused and the user is dragging up, the gesture should be run - otherwise it shouldn't.
        {
            return focused
        }
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        guard let tabBarItemViews = tabBar.subviews.first(where: {$0 is UIScrollView})?.subviews else { return }
        
        if let nextFocusedView = context.nextFocusedView, tabBarItemViews.contains(nextFocusedView) {
            tabBar.tintColor = .white
        } else if let previouslyFocusedView = context.previouslyFocusedView, tabBarItemViews.contains(previouslyFocusedView) {
            tabBar.tintColor = .darkGray
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? InfoViewController {
            infoViewController = vc
        } else if let vc = segue.destination as? SubtitlesViewController {
            subtitlesViewController = vc
        } else if let vc = segue.destination as? AudioViewController {
            audioViewController = vc
        }
    }
}
