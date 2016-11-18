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

#import "VLCTransportBar.h"
#import "VLCBufferingBar.h"

@interface VLCTransportBar ()
@property (nonatomic) VLCBufferingBar *bufferingBar;
@property (nonatomic) UIView *scrubbingPostionMarker;

@property (nonatomic) UIImageView *leftHintImageView;
@property (nonatomic) UIImageView *rightHintImageView;
@property (nonatomic) UIImageView *screenshotImageView;
@end

@implementation VLCTransportBar

static const CGFloat VLCTransportBarMarkerWidth = 2.0;

static inline void sharedSetup(VLCTransportBar *self) {
    CGRect bounds = self.bounds;
    
    // Bar:
    VLCBufferingBar *bar = [[VLCBufferingBar alloc] initWithFrame:bounds];

    bar.bufferColor = [UIColor lightGrayColor];
    bar.borderColor = [UIColor grayColor];
    bar.elapsedColor = [UIColor whiteColor];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bar.bufferProgress = self.bufferProgress;
    self.bufferingBar = bar;
    [self addSubview:bar];

    // Marker:
    UIView *scrubbingMarker = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VLCTransportBarMarkerWidth, CGRectGetHeight(bounds))];
    [self addSubview:scrubbingMarker];
    scrubbingMarker.backgroundColor = [UIColor clearColor];
    self.scrubbingPostionMarker = scrubbingMarker;

    // Labels:
    CGFloat size = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout].pointSize;
    UIFont *font = [UIFont monospacedDigitSystemFontOfSize:size weight:UIFontWeightSemibold];
    UIColor *textColor = [UIColor whiteColor];

    UILabel *markerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    markerLabel.font = font;
    markerLabel.textColor = textColor;
    [self addSubview:markerLabel];
    self->_elapsedTimeLabel = markerLabel;

    UILabel *remainingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    remainingLabel.font = font;
    remainingLabel.textColor = textColor;
    [self addSubview:remainingLabel];
    self->_remainingTimeLabel = remainingLabel;
    
    // Snapshot placeholder:
    self.screenshotImageView = [[UIImageView alloc] init];
    //center view to the scrubbing marker
    self.screenshotImageView.frame = CGRectMake(self.scrubbingPostionMarker.frame.origin.x-240, self.scrubbingPostionMarker.frame.origin.y-300, 480, 270);
    //add screenshot to the scrubbing marker so that they move as one unit, looks cleaner to the user
    [self.scrubbingPostionMarker addSubview:self.screenshotImageView];

    CGFloat iconLength = 32.0;
    CGRect imageRect = CGRectMake(0, 0, iconLength, iconLength);

    UIImageView *leftHintImageView = [[UIImageView alloc] initWithFrame:imageRect];
    [self addSubview:leftHintImageView];
    self.leftHintImageView = leftHintImageView;
    self.leftHintImageView.tintColor = [UIColor whiteColor];

    UIImageView *rightHintImageView = [[UIImageView alloc] initWithFrame:imageRect];
    [self addSubview:rightHintImageView];
    self.rightHintImageView = rightHintImageView;
    self.rightHintImageView.tintColor = [UIColor whiteColor];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        sharedSetup(self);
    }
    return self;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    sharedSetup(self);
}

- (void)setBufferProgress:(CGFloat)bufferProgress {
    _bufferProgress = bufferProgress;
    self.bufferingBar.bufferProgress = bufferProgress;
}

- (void)setProgress:(CGFloat)progress {
    if (progress < 0.0) progress = 0.0;
    if (progress > 1.0) progress = 1.0;
    _progress = progress;
    self.bufferingBar.elapsedProgress = progress;
    if (!self.scrubbing) {
        [self setScrubbingFraction:progress];
    }
    [self setNeedsLayout];
}

- (void)setScrubbingFraction:(CGFloat)scrubbingFraction {
    _progress = MAX(0.0, MIN(scrubbingFraction, 1.0));
    [self setNeedsLayout];
}

- (void)setScrubbing:(BOOL)scrubbing {
    _scrubbing = scrubbing;
    if(scrubbing)
        self.scrubbingPostionMarker.backgroundColor = [UIColor whiteColor];
    else{
        self.scrubbingPostionMarker.backgroundColor = [UIColor clearColor];
        self.screenshotImageView.image = nil;
    }
    [self setNeedsLayout];
}

-(void)setScreenshot:(UIImage*)screenshot{
    [self.screenshotImageView setImage:screenshot];
    _screenshot = screenshot;
}

- (UIImage *)imageForHint:(VLCTransportBarHint)hint
{
    NSString *imageName = nil;
    switch (hint) {
        case VLCTransportBarHintScanForward:
            imageName = @"FastForward";
            break;
        case VLCTransportBarHintJumpForward10:
            imageName = @"SkipForward";
            break;
        case VLCTransportBarHintJumpBackward10:
            imageName = @"SkipBack";
            break;
        case VLCTransportBarHintPaused:
            imageName = @"Pause";
            break;
        default:
            break;
	}
    if (imageName) {
        return [[UIImage imageNamed: imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return nil;
}
- (void)setHint:(VLCTransportBarHint)hint
{
    _hint = hint;
    UIImage *leftImage = nil;
    UIImage *rightImage = nil;
	switch (hint) {
        case VLCTransportBarHintScanForward:
        case VLCTransportBarHintJumpForward10:
            rightImage = [self imageForHint:hint];
			break;
        case VLCTransportBarHintJumpBackward10:
            leftImage = [self imageForHint:hint];
            break;
        case VLCTransportBarHintPaused:
            leftImage = [self imageForHint:hint];
            break;
        default:
			break;
	}

    // TODO: add animations
    self.leftHintImageView.image = leftImage;
    self.rightHintImageView.image = rightImage;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    const CGRect bounds = self.bounds;
    const CGFloat width = CGRectGetWidth(bounds)-VLCTransportBarMarkerWidth;


    const BOOL withThumbnail = NO;
    const CGRect scrubberFrame = scrubbingMarkerFrameForBounds_fraction_withThumb(bounds,
                                                                                  self.progress,
                                                                                  withThumbnail);
    self.scrubbingPostionMarker.frame = scrubberFrame;
    

    UILabel *remainingLabel = self.remainingTimeLabel;
    [remainingLabel sizeToFit];
    CGRect remainingLabelFrame = remainingLabel.frame;
    remainingLabelFrame.origin.y = CGRectGetMaxY(bounds)+15.0;
    remainingLabelFrame.origin.x = width-CGRectGetWidth(remainingLabelFrame);
    remainingLabel.frame = remainingLabelFrame;

    UILabel *markerLabel = self.elapsedTimeLabel;
    [markerLabel sizeToFit];

    CGPoint timeLabelCenter = remainingLabel.center;
    timeLabelCenter.x = self.scrubbingPostionMarker.center.x;
    markerLabel.center = timeLabelCenter;

    CGRect markerLabelFrame = markerLabel.frame;

    UIImageView *leftHint = self.leftHintImageView;
    CGFloat leftImageSize = CGRectGetWidth(leftHint.bounds);
    leftHint.center = CGPointMake(CGRectGetMinX(markerLabelFrame)-leftImageSize, timeLabelCenter.y);

    UIImageView *rightHint = self.rightHintImageView;
    CGFloat rightImageSize = CGRectGetWidth(rightHint.bounds);
    rightHint.center = CGPointMake(CGRectGetMaxX(markerLabelFrame)+rightImageSize, timeLabelCenter.y);

    CGFloat remainingAlfa = CGRectIntersectsRect(markerLabel.frame, remainingLabelFrame) ? 0.0 : 1.0;
    remainingLabel.alpha = remainingAlfa;
 }


static CGRect scrubbingMarkerFrameForBounds_fraction_withThumb(CGRect bounds, CGFloat fraction, BOOL withThumbnail) {
    const CGFloat width = CGRectGetWidth(bounds)-VLCTransportBarMarkerWidth;
    const CGFloat height = CGRectGetHeight(bounds);

    // when scrubbing marker is 4x instead of 3x bar heigt
    const CGFloat scrubbingHeight = height * (withThumbnail ? 4.0 : 3.0);

    // x position is always center of marker == view width * fraction
    const CGFloat scrubbingXPosition = width*fraction;
    CGFloat scrubbingYPosition = 0;
    if (withThumbnail) {
        // scrubbing marker bottom and bar buttom are same
        scrubbingYPosition = height-scrubbingHeight;
    } else {
        // scrubbing marker y center == bar y center
        scrubbingYPosition = height/2.0 - scrubbingHeight/2.0;
    }
    return CGRectMake(scrubbingXPosition,
                      scrubbingYPosition,
                      VLCTransportBarMarkerWidth,
                      scrubbingHeight);
}

@end
