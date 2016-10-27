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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, VLCTransportBarHint) {
    VLCTransportBarHintNone,
    VLCTransportBarHintScanForward,
    VLCTransportBarHintJumpForward10,
    VLCTransportBarHintJumpBackward10,
};

IB_DESIGNABLE @interface VLCTransportBar : UIView
@property (nonatomic) IBInspectable CGFloat progress;
@property (nonatomic) IBInspectable CGFloat bufferProgress;
@property (nonatomic) IBInspectable UIImage *screenshot;
@property (nonatomic, getter=isScrubbing) IBInspectable BOOL scrubbing;

@property (nonatomic, readonly) UILabel *elapsedTimeLabel;
@property (nonatomic, readonly) UILabel *remainingTimeLabel;

@property (nonatomic) VLCTransportBarHint hint;

@end

NS_ASSUME_NONNULL_END
