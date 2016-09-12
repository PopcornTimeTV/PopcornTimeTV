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
@property (nonatomic) CAShapeLayer *borderMaskLayer;
@property (nonatomic) CAShapeLayer *fillLayer;
@property (nonatomic) CAShapeLayer *fillMaskLayer;
@property (nonatomic) CAShapeLayer *coverMaskLayer;
@property (nonatomic) CAShapeLayer *coverLayer;

@end

@implementation VLCBufferingBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        _borderColor = [UIColor grayColor];
        _bufferColor = [UIColor lightGrayColor];

        _borderLayer = [CAShapeLayer layer];
        _borderLayer.fillColor = _borderColor.CGColor;
        
        _borderMaskLayer = [CAShapeLayer layer];
        _borderMaskLayer.fillColor = _borderColor.CGColor;
        _borderLayer.mask = _borderMaskLayer;

        [self.layer addSublayer:_borderLayer];

        _fillLayer = [CAShapeLayer layer];
        _fillLayer.fillColor = _bufferColor.CGColor;

        _fillMaskLayer = [CAShapeLayer layer];
        _fillMaskLayer.fillColor = [UIColor blackColor].CGColor;
        _fillLayer.mask = _fillMaskLayer;

        [self.layer addSublayer:_fillLayer];
        
        _coverLayer = [CAShapeLayer layer];
        _coverLayer.fillColor = [UIColor blackColor].CGColor;
        
        _coverMaskLayer = [CAShapeLayer layer];
        _coverMaskLayer.fillColor = [UIColor blackColor].CGColor;
        _coverLayer.mask = _coverMaskLayer;
        
        [self.layer addSublayer:_coverLayer];

    }
    return self;
}

- (void)setBufferColor:(UIColor *)bufferColor {
    _bufferColor = bufferColor;
    self.fillLayer.fillColor = bufferColor.CGColor;
}

- (void)setPlayingColor:(UIColor *)playingColor {
    _playingColor = playingColor;
    self.coverLayer.fillColor = playingColor.CGColor;
}


- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    self.borderLayer.fillColor = borderColor.CGColor;
}

- (void)setBufferStartFraction:(CGFloat)bufferStartFraction {
    _bufferStartFraction = bufferStartFraction;
    [self setNeedsLayout];
}
- (void)setBufferEndFraction:(CGFloat)bufferEndFraction {
    _bufferEndFraction = bufferEndFraction;
    [self setNeedsLayout];
}

- (void)setPlayerEndFraction:(CGFloat)playerEndFraction {
    _playerEndFraction = playerEndFraction;
    [self setNeedsLayout];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    CGFloat inset = self.borderLayer.lineWidth/2.0;
    CGRect borderRect = CGRectInset(bounds, inset, inset);
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:borderRect];// cornerRadius:cornerRadius];
    self.borderLayer.path = path.CGPath;
    self.borderMaskLayer.frame=bounds;
    self.borderMaskLayer.path=path.CGPath;
    
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
    CGRect playerRect = CGRectMake(CGRectGetWidth(bounds)*0,
                                   0,
                                   CGRectGetWidth(bounds)*(self.playerEndFraction-0),
                                   CGRectGetHeight(bounds));
    UIBezierPath *playerPath = [UIBezierPath bezierPathWithRect:playerRect];
    self.coverLayer.path=playerPath.CGPath;
    self.coverLayer.frame=bounds;
    self.coverMaskLayer.frame = bounds;
    self.coverMaskLayer.path = playerPath.CGPath;
}
@end

