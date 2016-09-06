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
    bar.playingColor = [UIColor colorWithRed:0.18 green:0.84 blue:0.40 alpha:1.0];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bar.bufferStartFraction = self.bufferStartFraction;
    bar.bufferEndFraction = self.bufferEndFraction;
    self.bufferingBar = bar;
    [self addSubview:bar];

    // Marker:
    self.screenshotImageView = [[UIImageView alloc] init];
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
    self->_markerTimeLabel = markerLabel;

    UILabel *remainingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    remainingLabel.font = font;
    remainingLabel.textColor = textColor;
    [self addSubview:remainingLabel];
    self->_remainingTimeLabel = remainingLabel;


    CGFloat iconLength = 32.0;
    CGRect imageRect = CGRectMake(0, 0, iconLength, iconLength);

    UIImageView *leftHintImageView = [[UIImageView alloc] initWithFrame:imageRect];
    [self addSubview:leftHintImageView];
    self.leftHintImageView = leftHintImageView;

    UIImageView *rightHintImageView = [[UIImageView alloc] initWithFrame:imageRect];
    [self addSubview:rightHintImageView];
    self.rightHintImageView = rightHintImageView;
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

- (void)setBufferStartFraction:(CGFloat)bufferStartFraction {
    CGFloat fraction = MAX(0.0, MIN(bufferStartFraction, 1.0));
    _bufferStartFraction = fraction;
    self.bufferingBar.bufferStartFraction = fraction;
}
- (void)setBufferEndFraction:(CGFloat)bufferEndFraction {
    CGFloat fraction = MAX(0.0, MIN(bufferEndFraction, 1.0));
    _bufferEndFraction = fraction;
    self.bufferingBar.bufferEndFraction = fraction;
}
- (void)setPlaybackEndFraction:(CGFloat)playbackEndFraction {   
    CGFloat fraction = MAX(0.0, MIN(playbackEndFraction, 1.0));
    _playbackEndFraction = fraction;
    self.bufferingBar.playerEndFraction = fraction;
    if (!self.scrubbing) {
        [self setScrubbingFraction:fraction];
    }
    [self setNeedsLayout];
}
- (void)setScrubbingFraction:(CGFloat)scrubbingFraction {
    _scrubbingFraction = MAX(0.0, MIN(scrubbingFraction, 1.0));
    [self setNeedsLayout];
}
- (void)setScrubbing:(BOOL)scrubbing {
    _scrubbing = scrubbing;
    if(scrubbing)
        self.scrubbingPostionMarker.backgroundColor = [UIColor whiteColor];
    else
        self.scrubbingPostionMarker.backgroundColor = [UIColor clearColor];
    [self setNeedsLayout];
}

-(void)setScreenshot:(UIImage*)screenshot{
    [self.screenshotImageView setImage:screenshot];
    _screenshot = screenshot;
    [self setNeedsLayout];
}

- (UIImage *)imageForHint:(VLCTransportBarHint)hint
{
    NSString *imageName = nil;
    switch (hint) {
        case VLCTransportBarHintScanForward:
            imageName = @"NowPlayingFastForward.png";
            break;
        case VLCTransportBarHintJumpForward10:
            imageName = @"NowPlayingSkip10Forward.png";
            break;
        case VLCTransportBarHintJumpBackward10:
            imageName = @"NowPlayingSkip10Backward.png";
            break;
        default:
			break;
	}
    if (imageName) {
        // FIXME: TODO: don't use the images from AVKit
        NSBundle *bundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/AVKit.framework"];
        return [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
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

    //self.playbackPositionMarker.center = CGPointMake(width*self.playbackFraction+VLCTransportBarMarkerWidth/2.0,
                                                     //CGRectGetMidY(bounds));


    const BOOL withThumbnail = NO;
    const CGRect scrubberFrame = scrubbingMarkerFrameForBounds_fraction_withThumb(bounds,
                                                                                  self.scrubbingFraction,
                                                                                  withThumbnail);
    self.scrubbingPostionMarker.frame = scrubberFrame;
    if (_screenshot != nil && _scrubbing){
        float leftBorder;
        if(self.scrubbingPostionMarker.frame.origin.x+240 <= self.bounds.size.width){
            leftBorder = self.scrubbingPostionMarker.frame.origin.x-240 >=0 ?self.scrubbingPostionMarker.frame.origin.x-240:0;
        }else{
            leftBorder = self.scrubbingPostionMarker.frame.origin.x+240 <= self.bounds.size.width ?self.scrubbingPostionMarker.frame.origin.x-240:self.bounds.origin.x+self.bounds.size.width-240;
        }
        self.screenshotImageView.frame=CGRectMake(leftBorder, self.scrubbingPostionMarker.frame.origin.y-300, 480, 270);
        [self addSubview:self.screenshotImageView];
    }else{
        self.screenshotImageView.image = nil;
    }

    UILabel *remainingLabel = self.remainingTimeLabel;
    [remainingLabel sizeToFit];
    CGRect remainingLabelFrame = remainingLabel.frame;
    remainingLabelFrame.origin.y = CGRectGetMaxY(bounds)+15.0;
    remainingLabelFrame.origin.x = width-CGRectGetWidth(remainingLabelFrame);
    remainingLabel.frame = remainingLabelFrame;

    UILabel *markerLabel = self.markerTimeLabel;
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