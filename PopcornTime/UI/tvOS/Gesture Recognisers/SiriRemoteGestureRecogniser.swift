

import Foundation
import UIKit.UIGestureRecognizerSubclass

enum SiriRemoteTouchLocation {
    case unknown
    case left
    case right
}

class SiriRemoteGestureRecognizer: UIGestureRecognizer {
    var minimumLongPressDuration: TimeInterval = 0.5
    var minimumLongTapDuration: TimeInterval = 1.0
    
    private(set) var isLongPress = false
    private (set) var isLongTap = false
    var isClick = false
    
    var touchLocation: SiriRemoteTouchLocation = .unknown
    
    private var longPressTimer: Timer?
    private var longTapTimer: Timer?
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        cancelsTouchesInView = false
    }
    
    
    // MARK: Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        longTapTimer?.invalidate()
        longTapTimer = Timer.scheduledTimer(timeInterval: minimumLongTapDuration, target: self, selector: #selector(longTapTimerFired), userInfo: nil, repeats: false)
        
        state = .began
        updateTouchLocation(with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        updateTouchLocation(with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        updateTouchLocation(with: .unknown)
        state = .cancelled
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        updateTouchLocation(with: .unknown)
        state = .ended
    }
    
    func updateTouchLocation(with event: UIEvent) {
        let location: SiriRemoteTouchLocation
        
        switch event.digitizerLocation.x {
        case let x where x <= 0.2:
            location = .left
        case let x where x >= 0.8:
            location = .right
        default:
            location = .unknown
        }
        
        updateTouchLocation(with: location)
    }
    
    func updateTouchLocation(with location: SiriRemoteTouchLocation) {
        guard touchLocation != location else { return }
        
        touchLocation = location
        state = .changed
    }
    
    override func reset() {
        isClick = false
        touchLocation = .unknown
        isLongPress = false
        isLongTap =  false
        
        longTapTimer?.invalidate()
        longPressTimer?.invalidate()
        
        longTapTimer = nil
        longPressTimer = nil
        
        super.reset()
    }
    
    // MARK: Timers
    
    @objc func longPressTimerFired() {
        guard isClick && state == .began || state == .changed else { return }
        isLongPress = true
        isClick = false
        state = .changed
    }
    
    @objc func longTapTimerFired() {
        guard state == .began || state == .changed else { return }
        isLongTap = true
        state = .changed
    }
    
    // MARK: Presses
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        guard let type = presses.first?.type, allowedPressTypes.contains(NSNumber(value: type.rawValue)) else { return }
        isClick = true
        
        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(timeInterval: minimumLongPressDuration, target: self, selector: #selector(longPressTimerFired), userInfo: nil, repeats: false)
        
        state = .changed
    }
    
    override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        state = .changed
    }
    
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        state = .cancelled
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        guard isClick || isLongPress else { return }
        state = .ended
    }
}

extension UIEvent {
    @nonobjc var digitizerLocation: CGPoint {
        guard let value = value(forKey: "_digitizerLocation") as? CGPoint else { return CGPoint(x: 0.5, y: 0.5) }
        return value
    }
}
