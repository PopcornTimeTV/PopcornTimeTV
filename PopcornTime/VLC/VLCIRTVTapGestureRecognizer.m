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

#import "VLCIRTVTapGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface UIPress (VLCSynthetic)
// A press is synthetic if it is a tap on the Siri remote touchpad
// which is synthesized to an arrow press.
- (BOOL)vlc_isSynthetic;
@end

@implementation UIPress (VLCSynthetic)

- (BOOL)vlc_isSynthetic
{
    /*
     * !!! Attention: We are using private API !!!
     * !!!  Might break in any future release  !!!
     *
     * For internal name changes the press might wrongly detected as non-synthetic.
     * Since we us it to filter for only non-synthetic presses arrow taps
     * on the Siri remote might be additionally be detected.
     */
    NSString *key = [@"isSyn" stringByAppendingString:@"thetic"];
    NSNumber *value = [self valueForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }
    return NO;
}
@end

@implementation VLCIRTVTapGestureRecognizer
- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    [presses enumerateObjectsUsingBlock:^(UIPress * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj vlc_isSynthetic]) {
            [self ignorePress:obj forEvent:event];
        }
    }];

    [super pressesBegan:presses withEvent:event];
}

@end
