

public protocol HeaderScrollViewDelegate {
    func headerDidScroll(_ headerView: UIView, progress: Float)
}

private enum ScrollDirection {
    case down
    case up
}

@IBDesignable open class HeaderScrollView: UIScrollView {
    
    @IBOutlet var headerView: UIView! = UIView()
    
    @IBInspectable var maximumHeaderHeight: CGFloat = 230
    
    @IBInspectable var minimumHeaderHeight: CGFloat = 22
    
    @IBOutlet var headerHeightConstraint: NSLayoutConstraint!
    
    open var programaticScrollEnabled = false
    
    fileprivate var scrollViewScrollingProgress: CGFloat {
        return (contentOffset.y + contentInset.top) / (contentSize.height + contentInset.top + contentInset.bottom - bounds.size.height)
    }
    fileprivate var overallScrollingProgress: CGFloat {
        return headerScrollingProgress * scrollViewScrollingProgress
    }
    fileprivate var headerScrollingProgress: CGFloat {
        get {
            return 1.0 - (headerHeightConstraint.constant - minimumHeaderHeight)/(maximumHeaderHeight - minimumHeaderHeight)
        }
    }
    
    fileprivate var lastTranslation: CGFloat = 0.0
    
    
    override open var contentOffset: CGPoint {
        didSet {
            if !programaticScrollEnabled {
                super.contentOffset = CGPoint.zero
            }
        }
    }
    
    @IBAction func handleGesture(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view!.superview!)
        let offset = translation.y - lastTranslation
        let scrollDirection: ScrollDirection = offset > 0 ? .up : .down
        
        if sender.state == .changed || sender.state == .began {
            if (headerHeightConstraint.constant + offset) >= minimumHeaderHeight && programaticScrollEnabled == false {
                if ((headerHeightConstraint.constant + offset) - minimumHeaderHeight) <= 8.0 // Stops scrolling from sticking just before we transition to scroll view input.
                {
                    headerHeightConstraint.constant = minimumHeaderHeight
                    updateScrolling(animated: true)
                } else {
                    headerHeightConstraint.constant += offset
                    updateScrolling(animated: false)
                }
            }
            if headerHeightConstraint.constant == minimumHeaderHeight && isAtTop {
                if scrollDirection == .up {
                    programaticScrollEnabled = false
                } else // If header is fully collapsed and we are not at the end of scroll view, hand scrolling to scroll view
                {
                    programaticScrollEnabled = true
                }
            }
            lastTranslation = translation.y
        } else if sender.state == .ended {
            if isOverScrollingTop {
                headerHeightConstraint.constant = maximumHeaderHeight
                updateScrolling(animated: true)
            }
            if isOverScrollingBottom {
                scrollToEnd(animated: true)
            }
            lastTranslation = 0.0
        }
    }
    
    func updateScrolling(animated: Bool) {
        guard animated else { superview?.layoutIfNeeded(); return }
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3, options: [.allowUserInteraction, .curveEaseOut], animations: {
            self.superview?.layoutIfNeeded()
        }, completion: nil)
    }
    
    func scrollToEnd(animated: Bool) {
        headerHeightConstraint.constant -= verticalOffsetForBottom
        
        if headerHeightConstraint.constant > maximumHeaderHeight { headerHeightConstraint.constant = maximumHeaderHeight }
        
        if headerHeightConstraint.constant >= minimumHeaderHeight // User does not go over the "bridge area" so programmatic scrolling has to be explicitly disabled
        {
            programaticScrollEnabled = false
        }
        updateScrolling(animated: animated)
    }
}

// MARK: - Scroll View Helper Variables

extension HeaderScrollView {
    @nonobjc var isOverScrollingBottom: Bool {
        return bounds.height > contentSize.height + contentInset.bottom
    }
    
    @nonobjc var isOverScrollingTop: Bool {
        return headerHeightConstraint.constant > maximumHeaderHeight
    }
    
    @nonobjc var isOverScrolling: Bool {
        return isOverScrollingTop || isOverScrollingBottom
    }
    
    @nonobjc var overScrollingBottomFraction: CGFloat {
        return (contentInset.bottom + contentSize.height)/bounds.height
    }
    
    @nonobjc var overScrollingTopFraction: CGFloat {
        return maximumHeaderHeight/headerHeightConstraint.constant
    }
}

extension UIScrollView {
    @nonobjc var isAtTop: Bool {
        return contentOffset.y <= verticalOffsetForTop
    }
    
    @nonobjc var isAtBottom: Bool {
        return contentOffset.y >= verticalOffsetForBottom
    }
    
    @nonobjc var verticalOffsetForTop: CGFloat {
        let topInset = contentInset.top
        return -topInset
    }
    
    @nonobjc var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = bounds.height
        let scrollContentSizeHeight = contentSize.height
        let bottomInset = contentInset.bottom
        let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
        return scrollViewBottomOffset
    }
}
