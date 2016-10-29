

import UIKit
import PopcornKit


class OptionsViewController: UIViewController, UIGestureRecognizerDelegate, UITabBarDelegate {

    var interactor: OptionsPercentDrivenInteractiveTransition?

    @IBOutlet var infoContentView: UIView!
    @IBOutlet var subtitlesContentView: UIView!
    @IBOutlet var audioContentView: UIView!

    @IBOutlet var tabBar: UITabBar!
    @IBOutlet var panGesture: UIPanGestureRecognizer!

    var infoViewController: InfoViewController!
    var subtitlesViewController: SubtitlesViewController!
    var audioViewController: AudioViewController!

    @IBAction func handleOptionsGesture(_ sender: UIPanGestureRecognizer) {
        let percentThreshold: CGFloat = 0.4
        let superview = sender.view!.superview!
        let translation = sender.translation(in: superview)
        let progress = -translation.y/superview.bounds.height

        guard let interactor = interactor else { return }

        switch sender.state {
        case .began:
            interactor.hasStarted = true
            dismiss(animated: true, completion: nil)
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
        if gestureRecognizer == panGesture, let focused = tabBar.subviews.first(where: {$0 is UIScrollView})?.subviews.contains(where: { $0.isFocused }) // If gesture is pan gesture and one of the buttons is focused and the user is dragging up, the gesture should be run - otherwise it shouldn't.
        {
            return focused ? {
                let velocity = panGesture.velocity(in: view)
                return fabs(velocity.y) > fabs(velocity.x) // If user is scrolling horizontally the gesture should not be run.
            }() : false
        }
        return true
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
