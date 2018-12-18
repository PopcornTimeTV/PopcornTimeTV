

import Foundation

class TVBlurOverCurrentContextAnimatedTransitioning: TVAppDocumentControllerAnimatedTransitioning {
    
    override func animatePresentationWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentingControllerView = transitionContext.view(forKey: .to)
            else {
                return
        }
        
        let view = TVVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.contentView.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
        view.frame = transitionContext.containerView.bounds
        view.blurRadius = 0.0
        
        transitionContext.containerView.addSubview(view)
        
        transitionContext.containerView.addSubview(presentingControllerView)
        presentingControllerView.transform = self.transformFrom
        presentingControllerView.alpha = 0.0
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .curveEaseIn, animations: {
            view.blurRadius = 120
            presentingControllerView.transform = .identity
            presentingControllerView.alpha = 1.0
        }, completion: { completed in
            presentingControllerView.insertSubview(view, at: 0)
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    override func animateDismissalWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentedControllerView = transitionContext.view(forKey: .from),
            let view = presentedControllerView.recursiveSubviews.compactMap({$0 as? TVVisualEffectView}).first
            else {
                return
        }
        
        transitionContext.containerView.addSubview(view)
        transitionContext.containerView.addSubview(presentedControllerView)
            
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .curveEaseIn, animations: {
            view.blurRadius = 0
            view.contentView.backgroundColor = nil
            presentedControllerView.transform = self.transformFrom
            presentedControllerView.alpha = 0.0
        }, completion: { completed in
            view.removeFromSuperview()
            presentedControllerView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
