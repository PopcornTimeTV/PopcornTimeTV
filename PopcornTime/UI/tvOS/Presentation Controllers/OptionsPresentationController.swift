

import Foundation

class OptionsPresentationController: UIPresentationController {
    
    var containerContentSize = CGSize.zero
    
    lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    func dimmingViewTapped(_ gesture: UIGestureRecognizer) {
        if gesture.state == .recognized {
            presentingViewController.dismiss(animated: true)
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
            self?.dimmingView.alpha = 0.6
            })
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] context in
            self?.dimmingView.alpha = 0
            })
    }
    
    override var frameOfPresentedViewInContainerView : CGRect {
        let screenSize = UIScreen.main.bounds.size
        if containerContentSize.height < screenSize.height {
            return CGRect(x: 0, y: 0, width: containerView?.bounds.width ?? containerContentSize.width, height: containerContentSize.height)
        }
        return CGRect(origin: CGPoint.zero, size: screenSize)
    }
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        if let bounds = containerView?.bounds {
            dimmingView.frame = bounds
        }
        if presentedView?.frame != frameOfPresentedViewInContainerView {
            UIView.animate(withDuration: 0.37, animations: { [unowned self] in
                self.presentedView?.frame = self.frameOfPresentedViewInContainerView
            })
        }
    }
}

class OptionsAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    let isPresenting: Bool
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)  {
        if isPresenting {
            animatePresentationWithTransitionContext(transitionContext)
        }
        else {
            animateDismissalWithTransitionContext(transitionContext)
        }
    }
    
    
    func animatePresentationWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentedControllerView = transitionContext.view(forKey: UITransitionContextViewKey.to)
            else {
                return
        }
        
        transitionContext.containerView.addSubview(presentedControllerView)
        presentedControllerView.frame.origin.y = -presentedControllerView.frame.height
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            presentedControllerView.frame.origin.y = 0
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
            presentedControllerView.frame.origin.y = -presentedControllerView.frame.height
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
