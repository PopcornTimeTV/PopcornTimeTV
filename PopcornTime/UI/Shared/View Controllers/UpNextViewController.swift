

import UIKit
import SwiftyTimer

#if os(tvOS)
    import MBCircularProgressBar
#endif

protocol UpNextViewControllerDelegate: class {
    func viewController(_ viewController: UpNextViewController, proceedToNextVideo proceed: Bool)
}

class UpNextViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var playNextButton: UIButton!
    
    weak var delegate: UpNextViewControllerDelegate?
    
    private var timer: Timer?
    private var updateTimer: Timer?
    
    // iOS Exclusive
    
    @IBOutlet var subtitleLabel: UILabel?
    @IBOutlet var infoLabel: UILabel?
    @IBOutlet var countdownLabel: UILabel?
    
    // tvOS Exclusive
    
    @IBOutlet var summaryView: UITextView?
    @IBOutlet var containerView: UIView?
    
    #if os(tvOS)
        @IBOutlet var countdownView: MBCircularProgressBarView!
    #endif
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startTimers()
        
        if UIDevice.current.userInterfaceIdiom == .tv,
            let presentingViewController = transitionCoordinator?.viewController(forKey: .from) as? PCTPlayerViewController {
            
            let movieView: UIView = presentingViewController.movieView
            
            containerView!.addSubview(movieView)
            movieView.translatesAutoresizingMaskIntoConstraints = true
            
            let frame = containerView!.convert(view.frame, from: view)
            movieView.frame = frame
            
            transitionCoordinator?.animate(alongsideTransition: { [unowned self, unowned movieView] _ in
                movieView.frame = self.containerView!.bounds
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimers()
        
        if UIDevice.current.userInterfaceIdiom == .tv,
            let presentingViewController = transitionCoordinator?.viewController(forKey: .to) as? PCTPlayerViewController {
            
            transitionCoordinator?.animate(alongsideTransition: { [unowned self, unowned presentingViewController] _ in
                presentingViewController.movieView.frame = self.containerView!.convert(self.view.frame, from: self.view)
            }) { [unowned presentingViewController] _ in
                presentingViewController.view.insertSubview(presentingViewController.movieView, at: 0)
                presentingViewController.movieView.frame = presentingViewController.view.bounds
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView?.layer.borderColor = UIColor(white: 1, alpha: 0.2).cgColor
        containerView?.layer.borderWidth = 1
    }
    
    func startTimers() {
        let initial = 30
        var delay = initial
        
        updateTimer = Timer.every(1.0) { [weak self] in
            guard let `self` = self, (delay - 1) >= 0 else { return }
            delay -= 1
            
            #if os(iOS)
                self.countdownLabel?.text = String(delay)
            #elseif os(tvOS)
                self.countdownView.value = CGFloat(delay)
            #endif
        }
        
        timer = Timer.after(TimeInterval(initial), { [weak self] in
            guard let `self` = `self` else { return }
            self.stopTimers()
            self.delegate?.viewController(self, proceedToNextVideo: true)
        })
    }
    
    func stopTimers() {
        timer?.invalidate()
        timer = nil
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @IBAction func cancel() {
        delegate?.viewController(self, proceedToNextVideo: false)
        stopTimers()
    }
    
    @IBAction func playNext() {
        stopTimers()
        delegate?.viewController(self, proceedToNextVideo: true)
    }
}
