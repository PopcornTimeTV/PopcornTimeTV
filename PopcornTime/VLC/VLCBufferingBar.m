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

#import "VLCBufferingBar.h"
@interface VLCBufferingBar()
@property (nonatomic) CAShapeLayer *borderLayer;
@property (nonatomic) CAShapeLayer *fillLayer;
@property (nonatomic) CAShapeLayer *fillMaskLayer;

@end

@implementation VLCBufferingBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        _borderColor = [UIColor lightGrayColor];
        _bufferColor = [UIColor lightGrayColor];

        _borderLayer = [CAShapeLayer layer];
        _borderLayer.lineWidth = 2.0;
        _borderLayer.fillColor = [UIColor clearColor].CGColor;
        _borderLayer.strokeColor = _borderColor.CGColor;

        [self.layer addSublayer:_borderLayer];

        _fillLayer = [CAShapeLayer layer];
        _fillLayer.fillColor = _bufferColor.CGColor;

        _fillMaskLayer = [CAShapeLayer layer];
        _fillMaskLayer.fillColor = [UIColor blackColor].CGColor;
        _fillLayer.mask = _fillMaskLayer;

        [self.layer addSublayer:_fillLayer];

    }
    return self;
}

- (void)setBufferColor:(UIColor *)bufferColor {
    _bufferColor = bufferColor;
    self.fillLayer.fillColor = bufferColor.CGColor;
}
- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    self.borderLayer.strokeColor = borderColor.CGColor;
}

- (void)setBufferStartFraction:(CGFloat)bufferStartFraction {
    _bufferStartFraction = bufferStartFraction;
    [self setNeedsLayout];
}
- (void)setBufferEndFraction:(CGFloat)bufferEndFraction {
    _bufferEndFraction = bufferEndFraction;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    CGFloat inset = self.borderLayer.lineWidth/2.0;
    CGRect borderRect = CGRectInset(bounds, inset, inset);
    CGFloat cornerRadius = CGRectGetMidY(bounds); // bounds is correct (flatter)
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:borderRect cornerRadius:cornerRadius];
    self.borderLayer.path = path.CGPath;

    CGRect bufferRect = CGRectMake(CGRectGetWidth(bounds)*self.bufferStartFraction,
                                   0,
                                   CGRectGetWidth(bounds)*(self.bufferEndFraction-self.bufferStartFraction),
                                   CGRectGetHeight(bounds));
    UIBezierPath *bufferPath = [UIBezierPath bezierPathWithRect:bufferRect];
    self.fillLayer.path = bufferPath.CGPath;
    self.borderLayer.frame = bounds;
    self.fillLayer.frame = bounds;
    self.fillMaskLayer.frame = bounds;
    self.fillMaskLayer.path = path.CGPath;
}
@end

