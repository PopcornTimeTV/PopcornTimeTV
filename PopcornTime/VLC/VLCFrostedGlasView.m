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
    CAGradientLayer *gradientUpper = [CAGradientLayer layer];
    gradientUpper.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height*0.2);
    gradientUpper.colors = [NSArray arrayWithObjects:  (id)[[UIColor blackColor] CGColor],(id)[[UIColor clearColor] CGColor], nil];
    gradientUpper.shadowOpacity = 0.8;
    [self.layer insertSublayer:gradientUpper atIndex:0];
    CAGradientLayer *gradientLower = [CAGradientLayer layer];
    gradientLower.colors = [NSArray arrayWithObjects: (id)[[UIColor clearColor] CGColor],(id)[[UIColor blackColor] CGColor], nil];
    gradientLower.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y+self.bounds.size.height-(self.bounds.size.height*0.2), self.bounds.size.width, self.bounds.size.height*0.2);
    gradientLower.shadowOpacity = 0.8;
    [self.layer insertSublayer:gradientLower atIndex:0];
}
@end
