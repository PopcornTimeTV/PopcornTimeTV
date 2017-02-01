

import UIKit

class EpisodeDetailPresentationController: UIPresentationController {
    
    var containerContentSize: CGSize = .zero
    
    lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        let tap = UITapGestureRecognizer(target:self, action:#selector(dimmingViewTapped))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    func dimmingViewTapped(_ gesture: UIGestureRecognizer) {
        if gesture.state == .recognized {
            presentingViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        containerContentSize = container.preferredContentSize
        containerViewDidLayoutSubviews()
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        dimmingView.frame = containerView!.bounds
        dimmingView.alpha = 0
        containerView?.insertSubview(dimmingView, at: 0)
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] context in
            self?.dimmingView.alpha = 0.3
        }, completion: nil)
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] context in
            self?.dimmingView.alpha = 0
        }, completion: nil)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let isCompact  = traitCollection.horizontalSizeClass == .compact
        let screenSize = UIScreen.main.bounds.size
        
        if isCompact {
            if containerContentSize.height < screenSize.height {
                return CGRect(x: 0, y: screenSize.height - containerContentSize.height, width: containerView?.bounds.width ?? containerContentSize.width, height: containerContentSize.height)
            }
            
            return CGRect(origin: CGPoint.zero, size: screenSize)
        } else if let containerView = containerView {
            let height: CGFloat = 572
            let width:  CGFloat = 524
            
            let origin = CGPoint(x: containerView.frame.midX - width/2.0, y: containerView.frame.midY - height/2.0)
            let size   = CGSize(width: width, height: height)
            
            return CGRect(origin: origin, size: size)
        }
        
        return super.frameOfPresentedViewInContainerView
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        
        if let bounds = containerView?.bounds {
            dimmingView.frame = bounds
        }
        
        presentedView?.layer.cornerRadius = traitCollection.horizontalSizeClass == .compact ? 0 : 10
        presentedView?.layer.masksToBounds = true
        
        if presentedView?.frame != frameOfPresentedViewInContainerView {
            UIView.animate(withDuration: animationLength, animations: { [unowned self] in
                self.presentedView?.frame = self.frameOfPresentedViewInContainerView
            }) 
        }
    }
}

class EpisodeDetailPercentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition {
    var hasStarted = false
    var shouldFinish = false
}

class EpisodeDetailAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
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
            let presentedControllerView = transitionContext.view(forKey: UITransitionContextViewKey.to),
            let presentedViewController = transitionContext.viewController(forKey: .to),
            let frame = presentedViewController.presentationController?.frameOfPresentedViewInContainerView
            else {
                return
        }
        
        
        transitionContext.containerView.addSubview(presentedControllerView)
        presentedControllerView.frame = frame
        presentedControllerView.frame.origin.y = UIScreen.main.bounds.height
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            presentedControllerView.frame.origin.y = frame.origin.y
            }, completion: { completed in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    func animateDismissalWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentedControllerView = transitionContext.view(forKey: UITransitionContextViewKey.from)
            else {
                return
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            presentedControllerView.frame.origin.y = UIScreen.main.bounds.height
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
