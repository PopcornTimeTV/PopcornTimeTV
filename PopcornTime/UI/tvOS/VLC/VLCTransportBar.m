

#import "VLCTransportBar.h"
#import "VLCBufferingBar.h"

@interface VLCTransportBar ()
@property (nonatomic) VLCBufferingBar *bufferingBar;
@property (nonatomic) UIView *playbackPositionMarker;
@property (nonatomic) UIView *scrubbingPositionMarker;
@property (nonatomic) UIActivityIndicatorView *bufferingMarker;

@property (nonatomic) UIImageView *leftHintImageView;
@property (nonatomic) UIImageView *rightHintImageView;
@property (nonatomic) UIImageView *screenshotImageView;
@end

@implementation VLCTransportBar

static const CGFloat VLCTransportBarMarkerWidth = 2.0;
static const CGFloat animationLength = 0.15;

static inline void sharedSetup(VLCTransportBar *self) {
    CGRect bounds = self.bounds;
    
    // Bar:
    VLCBufferingBar *bar = [[VLCBufferingBar alloc] initWithFrame:bounds];

    bar.bufferColor = [UIColor clearColor];
    bar.borderColor = [UIColor grayColor];
    bar.elapsedColor = [UIColor clearColor];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bar.bufferProgress = self.bufferProgress;
    self.bufferingBar = bar;
    [self addSubview:bar];
    
    
    // Snapshot placeholder:
    self.screenshotImageView = [[UIImageView alloc] init];
    self.screenshotImageView.clipsToBounds = YES;
    self.screenshotImageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
    self.screenshotImageView.backgroundColor = [UIColor blackColor];
    self.screenshotImageView.layer.borderWidth = 1.0;
    self.screenshotImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.screenshotImageView.frame = CGRectMake(0, 0, 480, 270);
    [self addSubview:self.screenshotImageView];
    
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
    
    UILabel *scrubLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.screenshotImageView.bounds.origin.x + (self.screenshotImageView.bounds.size.width/2) - 40, self.screenshotImageView.bounds.size.height - 50, 10, 10)];
    scrubLabel.font = font;
    scrubLabel.textColor = textColor;
    [self.screenshotImageView addSubview:scrubLabel];
    self->_scrubbingTimeLabel = scrubLabel;
    
    // Markers:
    UIView *scrubbingMarker = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VLCTransportBarMarkerWidth, bounds.size.height)];
    [self addSubview:scrubbingMarker];
    scrubbingMarker.backgroundColor = [UIColor whiteColor];
    scrubbingMarker.hidden = YES;
    self.scrubbingPositionMarker = scrubbingMarker;
    
    UIView *positionMarker = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VLCTransportBarMarkerWidth, bounds.size.height)];
    [self addSubview:positionMarker];
    positionMarker.backgroundColor = [UIColor whiteColor];
    self.playbackPositionMarker = positionMarker;
    
    CGFloat iconLength = 40.0;
    CGRect imageRect = CGRectMake(0, 0, iconLength, iconLength);
    
    UIActivityIndicatorView *bufferMarker = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [bufferMarker startAnimating];
    [self addSubview:bufferMarker];
    bufferMarker.frame = imageRect;
    self.bufferingMarker = bufferMarker;


    UIImageView *leftHintImageView = [[UIImageView alloc] initWithFrame:imageRect];
    [self addSubview:leftHintImageView];
    self.leftHintImageView = leftHintImageView;
    self.leftHintImageView.tintColor = [UIColor whiteColor];

    UIImageView *rightHintImageView = [[UIImageView alloc] initWithFrame:imageRect];
    [self addSubview:rightHintImageView];
    self.rightHintImageView = rightHintImageView;
    self.rightHintImageView.tintColor = [UIColor whiteColor];
    
    self.scrubbing = NO;
    self.buffering = NO;
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
    [self setNeedsLayout];
}

- (void)setProgress:(CGFloat)progress {
    if (progress < 0.0) progress = 0.0;
    if (progress > 1.0) progress = 1.0;
    _scrubbingProgress = progress;
    self.scrubbingTimeLabel.text = self.elapsedTimeLabel.text;
    if (!self.scrubbing) {
        _progress = progress;
        self.bufferingBar.elapsedProgress = progress;
        [self setScrubbingFraction:progress];
    }
    [self setNeedsLayout];
}

-(void)setScrubbingProgress:(CGFloat)scrubbingProgress {
    if (scrubbingProgress < 0.0) scrubbingProgress = 0.0;
    if (scrubbingProgress > 1.0) scrubbingProgress = 1.0;
    _scrubbingProgress = scrubbingProgress;
    [self setNeedsLayout];
}

- (void)setScrubbingFraction:(CGFloat)scrubbingFraction {
    _progress = MAX(0.0, MIN(scrubbingFraction, 1.0));
    [self setNeedsLayout];
}

- (void)setScrubbing:(BOOL)scrubbing {
    _scrubbing = scrubbing;
    if (scrubbing) {
        self.scrubbingProgress = self.progress;
        self.screenshotImageView.hidden = NO;
        self.scrubbingPositionMarker.hidden = NO;
        self.elapsedTimeLabel.textColor = [UIColor lightGrayColor];
        self.remainingTimeLabel.textColor = [UIColor lightGrayColor];
        self.playbackPositionMarker.alpha = 0.6;
    } else {
        self.playbackPositionMarker.alpha = 1.0;
        self.screenshotImageView.image = nil;
        self.screenshotImageView.hidden = YES;
        self.scrubbingPositionMarker.hidden = YES;
        self.elapsedTimeLabel.textColor = [UIColor whiteColor];
        self.remainingTimeLabel.textColor = [UIColor whiteColor];
    }
    [self setNeedsLayout];
}

- (void)setBuffering:(BOOL)buffering {
    _buffering = buffering;
    if (buffering) {
        self.bufferingMarker.hidden = NO;
        self.rightHintImageView.hidden = YES;
        self.leftHintImageView.hidden = YES;
    } else {
        self.bufferingMarker.hidden = YES;
        self.rightHintImageView.hidden = NO;
        self.leftHintImageView.hidden = NO;
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
            imageName = @"SkipForward30";
            break;
        case VLCTransportBarHintJumpBackward10:
            imageName = @"SkipBack30";
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

    self.leftHintImageView.image = leftImage;
    self.rightHintImageView.image = rightImage;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    const CGRect bounds = self.bounds;
    const CGFloat width = CGRectGetWidth(bounds)-VLCTransportBarMarkerWidth;

    
    const CGRect progressFrame = progressMarkerFrameForBounds(bounds, self.progress);
    const CGRect scrubberFrame = scrubbingMarkerFrameForBounds(bounds, self.scrubbingProgress);
    
    
    self.scrubbingPositionMarker.frame = scrubberFrame;
    self.playbackPositionMarker.frame = progressFrame;

    CGRect screenshotFrame = CGRectMake(scrubberFrame.origin.x - 240,
                                        scrubberFrame.origin.y - 270,
                                        480, 270);
    
    // Make sure image view is not off the screen.
    if (screenshotFrame.origin.x < bounds.origin.x) screenshotFrame.origin.x = bounds.origin.x;
    if (CGRectGetMaxX(screenshotFrame) > CGRectGetMaxX(bounds)) screenshotFrame.origin.x = CGRectGetMaxX(bounds) - screenshotFrame.size.width;
    
    self.screenshotImageView.frame = screenshotFrame;
    

    UILabel *remainingLabel = self.remainingTimeLabel;
    [remainingLabel sizeToFit];
    CGRect remainingLabelFrame = remainingLabel.frame;
    remainingLabelFrame.origin.y = CGRectGetMaxY(bounds)+15.0;
    remainingLabelFrame.origin.x = width-CGRectGetWidth(remainingLabelFrame);
    remainingLabel.frame = remainingLabelFrame;

    UILabel *markerLabel = self.elapsedTimeLabel;
    [markerLabel sizeToFit];
    
    UILabel *scrubLabel = self.scrubbingTimeLabel;
    scrubLabel.hidden = scrubLabel.text == markerLabel.text;
    [scrubLabel sizeToFit];
    

    CGPoint timeLabelCenter = remainingLabel.center;
    timeLabelCenter.x = self.playbackPositionMarker.center.x;
    markerLabel.center = timeLabelCenter;

    CGRect markerLabelFrame = markerLabel.frame;
    
    UIActivityIndicatorView *bufferMarker = self.bufferingMarker;
    CGFloat markerSize = CGRectGetWidth(bufferMarker.bounds);
    bufferMarker.center = CGPointMake(CGRectGetMaxX(markerLabelFrame)+markerSize, timeLabelCenter.y);

    UIImageView *leftHint = self.leftHintImageView;
    CGFloat leftImageSize = CGRectGetWidth(leftHint.bounds);
    leftHint.center = CGPointMake(CGRectGetMinX(markerLabelFrame)-leftImageSize, timeLabelCenter.y);

    UIImageView *rightHint = self.rightHintImageView;
    CGFloat rightImageSize = CGRectGetWidth(rightHint.bounds);
    rightHint.center = CGPointMake(CGRectGetMaxX(markerLabelFrame)+rightImageSize, timeLabelCenter.y);

    BOOL shouldHideRemainingTime = CGRectIntersectsRect(markerLabel.frame, remainingLabelFrame) || (CGRectIntersectsRect(rightHint.frame, remainingLabelFrame) && rightHint.image != nil) || (CGRectIntersectsRect(bufferMarker.frame, remainingLabelFrame) && bufferMarker.hidden == FALSE);
    CGFloat remainingAlpha = shouldHideRemainingTime ? 0.0 : 1.0;
    
    [UIView animateWithDuration:animationLength animations:^{
        remainingLabel.alpha = remainingAlpha;
    }];
    
 }


static CGRect scrubbingMarkerFrameForBounds(CGRect bounds, CGFloat fraction) {
    const CGFloat width = CGRectGetWidth(bounds)-VLCTransportBarMarkerWidth;
    const CGFloat height = CGRectGetHeight(bounds);

    const CGFloat scrubbingHeight = height * 3.0;

    // x position is always center of marker == view width * fraction
    const CGFloat scrubbingXPosition = width*fraction;
    CGFloat scrubbingYPosition = height-scrubbingHeight;
    
    return CGRectMake(scrubbingXPosition,
                      scrubbingYPosition,
                      VLCTransportBarMarkerWidth,
                      scrubbingHeight);
}

static CGRect progressMarkerFrameForBounds(CGRect bounds, CGFloat fraction) {
    const CGFloat width = CGRectGetWidth(bounds)-VLCTransportBarMarkerWidth;
    const CGFloat scrubbingHeight = CGRectGetHeight(bounds);
    
    // x position is always center of marker == view width * fraction
    const CGFloat scrubbingXPosition = width*fraction;
    
    return CGRectMake(scrubbingXPosition, 0, VLCTransportBarMarkerWidth, scrubbingHeight);
}

@end
