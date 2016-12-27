

import Foundation

class LoadingViewAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    let isPresenting: Bool
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)  {
        isPresenting ? animatePresentationWithTransitionContext(transitionContext) : animateDismissalWithTransitionContext(transitionContext)
    }
    
    
    func animatePresentationWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentedControllerView = transitionContext.view(forKey: .to),
            let presentingViewController = transitionContext.viewController(forKey: .from)
            else {
                return
        }
        
        transitionContext.containerView.addSubview(presentedControllerView)
        presentedControllerView.isHidden = true
        
        let view = UIView(frame: presentingViewController.view.bounds)
        view.backgroundColor = UIColor.black
        view.alpha = 0.0
        presentingViewController.view.addSubview(view)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                view.alpha = 0.4
        }, completion: { completed in
            view.removeFromSuperview()
            presentingViewController.navigationController?.setNavigationBarHidden(true, animated: false)
            presentedControllerView.isHidden = false
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    func animateDismissalWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentedControllerView = transitionContext.view(forKey: .from),
            let presentingControllerView = transitionContext.view(forKey: .to),
            let presentingViewController = transitionContext.viewController(forKey: .from)
            else {
                return
        }
        transitionContext.containerView.addSubview(presentingControllerView)
        presentedControllerView.isHidden = true
        presentingViewController.navigationController?.setNavigationBarHidden(false, animated: true)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {}, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

