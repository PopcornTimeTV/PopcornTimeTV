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
@interface VLCBufferingBar : UIView
@property (nonatomic) CGFloat bufferStartFraction;
@property (nonatomic) CGFloat bufferEndFraction;

@property (nonatomic) UIColor *bufferColor;
@property (nonatomic) UIColor *borderColor;
@end
NS_ASSUME_NONNULL_END