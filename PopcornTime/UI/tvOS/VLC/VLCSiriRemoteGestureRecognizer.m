

#import "VLCSiriRemoteGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface UIEvent (VLCDigitizerLocation)
- (CGPoint)vlc_digitizerLocation;
@end

@interface VLCSiriRemoteGestureRecognizer ()
{
	NSTimer *_longPressTimer;
    NSTimer *_longTapTimer;
}
@end

@implementation VLCSiriRemoteGestureRecognizer
@dynamic delegate;


- (nonnull instancetype)initWithTarget:(nullable id)target action:(nullable SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        self.allowedTouchTypes = @[@(UITouchTypeIndirect)];
        self.allowedPressTypes = @[@(UIPressTypeSelect)];
		self.minimumLongPressDuration = 0.5;
        self.minimumLongTapDuration = 1.0;
        self.cancelsTouchesInView = NO;
    }
    return self;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _longTapTimer = [NSTimer scheduledTimerWithTimeInterval:self.minimumLongTapDuration target:self selector:@selector(longTapTimerFired) userInfo:nil repeats:NO];
    
    self.state = UIGestureRecognizerStateBegan;
    [self updateTouchLocationWithEvent:event];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateTouchLocationWithEvent:event];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateTouchLocation:VLCSiriRemoteTouchLocationUnknown];
    self.state = UIGestureRecognizerStateEnded;
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateTouchLocation:VLCSiriRemoteTouchLocationUnknown];
    self.state = UIGestureRecognizerStateEnded;
}

- (void)updateTouchLocationWithEvent:(UIEvent *)event
{
    CGPoint digitizerLocation = [event vlc_digitizerLocation];
    VLCSiriRemoteTouchLocation location = VLCSiriRemoteTouchLocationUnknown;
    if (digitizerLocation.x <= 0.2) {
        location = VLCSiriRemoteTouchLocationLeft;
    } else if (0.8 <= digitizerLocation.x) {
        location = VLCSiriRemoteTouchLocationRight;
    }
    [self updateTouchLocation:location];
}

- (void)updateTouchLocation:(VLCSiriRemoteTouchLocation)location
{
	if (_touchLocation == location) {
		return;
	}

	_touchLocation = location;
    self.state = UIGestureRecognizerStateChanged;
}

- (void)reset
{
	_click = NO;
	_touchLocation = VLCSiriRemoteTouchLocationUnknown;
	_longPress = NO;
    _longTap = NO;
    [_longTapTimer invalidate];
	[_longPressTimer invalidate];
    _longTapTimer = nil;
	_longPressTimer = nil;
    [super reset];
}

- (void)longPressTimerFired
{
	if (_click && (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged)) {
		_longPress = YES;
        self.state = UIGestureRecognizerStateChanged;
    }
}

- (void)longTapTimerFired
{
    if (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged) {
        _longTap = YES;
        self.state = UIGestureRecognizerStateChanged;
    }
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
	if ([self.allowedPressTypes containsObject:@(presses.anyObject.type)]) {
		_click = YES;
		_longPressTimer = [NSTimer scheduledTimerWithTimeInterval:self.minimumLongPressDuration target:self selector:@selector(longPressTimerFired) userInfo:nil repeats:NO];
		self.state = UIGestureRecognizerStateChanged;
	}
}
- (void)pressesChanged:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
	self.state = UIGestureRecognizerStateChanged;
}
- (void)pressesCancelled:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
	self.state = UIGestureRecognizerStateCancelled;
}
- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
	if (_click) {
		self.state = UIGestureRecognizerStateEnded;
	}
}
@end


@implementation UIEvent (VLCDigitizerLocation)

- (CGPoint)vlc_digitizerLocation
{
    /*
     * !!! Attention: We are using private API !!!
     * !!!  Might break in any future release  !!!
     *
     * The digitizer location is the absolute location of the touch on the touch pad.
     * The location is in a 0,0 (top left) to 1,1 (bottom right) coordinate system.
     */
    NSString *key = [@"digitiz" stringByAppendingString:@"erLocation"];
    NSNumber *value = [self valueForKey:key];
    if ([value isKindOfClass:[NSValue class]]) {
        return [value CGPointValue];
    }
    // default to center position as undefined position
    return CGPointMake(0.5,0.5);
}

@end
