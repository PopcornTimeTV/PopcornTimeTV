

import Foundation

class TVAppDocumentControllerAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    /// Transform applied to presented view (previous view in stack) when view controller is being presented.
    let transformTo = CGAffineTransform(scaleX: 1.4, y: 1.4)
    
    /// Transform applied to dismissing view (current view in stack) when view controller is being dismissed.
    let transformFrom = CGAffineTransform(scaleX: 0.6, y: 0.6)
    
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
            let presentingControllerView = transitionContext.view(forKey: .from)
            else {
                return
        }
        
        transitionContext.containerView.addSubview(presentedControllerView)
        transitionContext.containerView.addSubview(presentingControllerView)
        presentedControllerView.alpha = 0.0
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            presentingControllerView.alpha = 0.0
            presentedControllerView.alpha = 1.0
            presentingControllerView.transform = self.transformTo
        }, completion: { completed in
            presentingControllerView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    func animateDismissalWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentedControllerView = transitionContext.view(forKey: .from),
            let presentingControllerView = transitionContext.view(forKey: .to)
            else {
                return
        }
        transitionContext.containerView.addSubview(presentedControllerView)
        transitionContext.containerView.addSubview(presentingControllerView)
        
        presentingControllerView.transform = self.transformTo // As if we've just come from that view and the transform has stuck
        presentingControllerView.alpha = 0.0
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            presentedControllerView.transform = self.transformFrom
            presentedControllerView.alpha = 0.0
            presentingControllerView.transform = .identity
            presentingControllerView.alpha = 1.0
        }, completion: { _ in
            presentedControllerView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
