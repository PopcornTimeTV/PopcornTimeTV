/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSiriRemoteGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface UIEvent (VLCDigitizerLocation)
- (CGPoint)vlc_digitizerLocation;
@end

@interface VLCSiriRemoteGestureRecognizer ()
{
	NSTimer *_longPressTimer;
}
@end

@implementation VLCSiriRemoteGestureRecognizer
@dynamic delegate;

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        self.allowedTouchTypes = @[@(UITouchTypeIndirect)];
        self.allowedPressTypes = @[@(UIPressTypeSelect)];
		self.minLongPressDuration = 0.5;
        self.cancelsTouchesInView = NO;
    }
    return self;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
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
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateTouchLocation:VLCSiriRemoteTouchLocationUnknown];
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
	[_longPressTimer invalidate];
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

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
	if ([self.allowedPressTypes containsObject:@(presses.anyObject.type)]) {
		_click = YES;
		_longPressTimer = [NSTimer scheduledTimerWithTimeInterval:self.minLongPressDuration target:self selector:@selector(longPressTimerFired) userInfo:nil repeats:NO];
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
     * The digitizer location is the absolut location of the touch on the touch pad.
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