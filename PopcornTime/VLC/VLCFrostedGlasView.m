/*****************************************************************************
 * VLCFrostedGlasView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan # org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFrostedGlasView.h"

@interface VLCFrostedGlasView ()
{
    BOOL _usingToolbarHack;
}

#if TARGET_OS_IOS
@property (nonatomic) UIToolbar *toolbar;
@property (nonatomic) UIImageView *imageview;
#endif
@property (nonatomic)  UIVisualEffectView *effectView;

@end

@implementation VLCFrostedGlasView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
        [self setupView];

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
        [self setupView];

    return self;
}

- (void)setupView
{
    [self setClipsToBounds:YES];

#if TARGET_OS_IOS
    if ([UIVisualEffectView class] != nil) {
        _effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        _effectView.frame = self.bounds;
        _effectView.clipsToBounds = YES;
        _effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self insertSubview:_effectView atIndex:0];
    } else {
        _usingToolbarHack = YES;
        if (![self toolbar]) {
            [self setToolbar:[[UIToolbar alloc] initWithFrame:[self bounds]]];
            [self.layer insertSublayer:[self.toolbar layer] atIndex:0];
            [self.toolbar setBarStyle:UIBarStyleBlack];
        }
    }
#else
    CAGradientLayer *gradientUpper = [CAGradientLayer layer];
    gradientUpper.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height*0.2);
    gradientUpper.colors = [NSArray arrayWithObjects:  (id)[[UIColor blackColor] CGColor],(id)[[UIColor clearColor] CGColor], nil];
    gradientUpper.shadowOpacity = 0.8;
//    _effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
//    _effectView.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height*0.15);
//    _effectView.alpha=0.6;
//    _effectView.clipsToBounds = YES;
//    _effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [[_effectView layer] addSublayer:gradient];
//    //[self insertSubview:_effectView atIndex:0];
    [self.layer insertSublayer:gradientUpper atIndex:0];
//    _effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
//    _effectView.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y+self.bounds.size.height-(self.bounds.size.height*0.15), self.bounds.size.width, self.bounds.size.height*0.15);
//    _effectView.alpha=0.6;
//    _effectView.clipsToBounds = YES;
//    _effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    CAGradientLayer *gradientLower = [CAGradientLayer layer];
    gradientLower.colors = [NSArray arrayWithObjects: (id)[[UIColor clearColor] CGColor],(id)[[UIColor blackColor] CGColor], nil];
    gradientLower.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y+self.bounds.size.height-(self.bounds.size.height*0.2), self.bounds.size.width, self.bounds.size.height*0.2);
    gradientLower.shadowOpacity = 0.8;
//    [[_effectView layer] addSublayer:gradient];
    //[self insertSubview:_effectView atIndex:1];
    [self.layer insertSublayer:gradientLower atIndex:0];
#endif
}

#if TARGET_OS_IOS
- (void)layoutSubviews {
    [super layoutSubviews];
    if (_usingToolbarHack) {
        [self.toolbar setFrame:[self bounds]];
    }
}
#endif

@end
