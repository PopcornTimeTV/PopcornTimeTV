

import UIKit
import PopcornKit


class OptionsViewController: UIViewController, UIGestureRecognizerDelegate, UITabBarDelegate {
    
    var interactor: OptionsPercentDrivenInteractiveTransition?
    
    @IBOutlet var infoContentView: UIView!
    @IBOutlet var subtitlesContentView: UIView!
    @IBOutlet var audioContentView: UIView!
    
    @IBOutlet var tabBar: UITabBar!
    
    var infoViewController: InfoViewController?
    
    var subtitlesViewController: SubtitlesViewController?
    
//    var audioViewController: AudioViewController {
//        return childViewControllers.first(where: { $0 is AudioViewController }) as! AudioViewController
//    }
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? InfoViewController {
            infoViewController = vc
        } else if let vc = segue.destination as? SubtitlesViewController {
            subtitlesViewController = vc
        }
    }
}
