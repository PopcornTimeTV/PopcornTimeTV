

import UIKit
import struct PopcornKit.Subtitle

protocol OptionsViewControllerDelegate: class {
    func didSelectSubtitle(_ subtitle: Subtitle?)
    func didSelectSubtitleDelay(_ delay: Int)
    func didSelectEncoding(_ encoding: String)
    func didSelectAudioDelay(_ delay: Int)
    func didSelectEqualizerProfile(_ profile: EqualizerProfiles)
}


class OptionsViewController: UIViewController, UIGestureRecognizerDelegate, UITabBarDelegate {
    
    weak var delegate: OptionsViewControllerDelegate?

    @IBOutlet var infoContainerView: UIView!
    @IBOutlet var subtitlesContainerView: UIView!
    @IBOutlet var audioContainerView: UIView!

    @IBOutlet var tabBar: UITabBar!
    @IBOutlet var swipeGesture: UISwipeGestureRecognizer!

    var infoViewController: InfoViewController!
    var subtitlesViewController: SubtitlesViewController!
    var audioViewController: AudioViewController!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        
        environmentsToFocus.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let menuGesture = UITapGestureRecognizer(target: self, action: #selector(menuPressed))
        menuGesture.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        menuGesture.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        
        view.addGestureRecognizer(menuGesture)
    }

    @IBAction func dismissOptionsViewController() {
        dismiss(animated: true)
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let index = tabBar.items!.index(of: item)!
        
        updateContainerView(infoContainerView, viewController: infoViewController, hidden: index != 0)
        updateContainerView(subtitlesContainerView, viewController: subtitlesViewController, hidden: index != 1)
        updateContainerView(audioContainerView, viewController: audioViewController, hidden: index != 2)
    }
    
    func updateContainerView(_ containerView: UIView, viewController: UIViewController, hidden: Bool) {
        guard hidden != containerView.isHidden else { return }
        
        hidden ? viewController.viewWillDisappear(false) : viewController.viewWillAppear(false)
        containerView.isHidden = hidden
        hidden ? viewController.viewDidDisappear(false) : viewController.viewDidAppear(false)
    }
    
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == swipeGesture, let focused = tabBar.subviews.first(where: {$0 is UIScrollView})?.subviews.contains(where: { $0.isFocused }) // If gesture is swipe gesture and one of the buttons is focused and the user is dragging up, the gesture should be run - otherwise, it shouldn't.
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
    
    var environmentsToFocus: [UIFocusEnvironment] = []
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return environmentsToFocus.isEmpty ? super.preferredFocusEnvironments : environmentsToFocus
    }
    
    @objc func menuPressed() {
        if tabBar.recursiveSubviews.filter({$0.isFocused}).isEmpty {
            environmentsToFocus = [tabBar]
            setNeedsFocusUpdate()
            updateFocusIfNeeded()
            environmentsToFocus.removeAll()
        } else {
            dismiss(animated: true)
        }
    }
}
