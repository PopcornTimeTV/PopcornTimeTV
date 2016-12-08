

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
        _borderLayer.borderWidth = 1.0;
        _borderLayer.borderColor = _borderColor.CGColor;
        _borderLayer.fillColor = [UIColor clearColor].CGColor;
        
        _borderMaskLayer = [CAShapeLayer layer];
        _borderLayer.mask = _borderMaskLayer;

        [self.layer addSublayer:_borderLayer];

        _fillLayer = [CAShapeLayer layer];
        _fillLayer.fillColor = _bufferColor.CGColor;

        _fillMaskLayer = [CAShapeLayer layer];
        _fillLayer.mask = _fillMaskLayer;

        [self.layer addSublayer:_fillLayer];
        
        _coverLayer = [CAShapeLayer layer];
        
        _coverMaskLayer = [CAShapeLayer layer];
        _coverLayer.mask = _coverMaskLayer;
        
        [self.layer addSublayer:_coverLayer];

    }
    return self;
}

- (void)setBufferColor:(UIColor *)bufferColor {
    _bufferColor = bufferColor;
    self.fillLayer.fillColor = bufferColor.CGColor;
}

- (void)setElapsedColor:(UIColor *)elapsedColor {
    _elapsedColor = elapsedColor;
    self.coverLayer.fillColor = elapsedColor.CGColor;
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    self.borderLayer.borderColor = borderColor.CGColor;
}

- (void)setBufferProgress:(CGFloat)bufferProgress {
    _bufferProgress = bufferProgress;
    [self setNeedsLayout];
}

- (void)setElapsedProgress:(CGFloat)elapsedProgress {
    _elapsedProgress = elapsedProgress;
    [self setNeedsLayout];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    CGFloat inset = self.borderLayer.lineWidth/2.0;
    CGRect borderRect = CGRectInset(bounds, inset, inset);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:borderRect cornerRadius:bounds.size.height/2.0];
    self.borderLayer.path = path.CGPath;
    self.borderMaskLayer.frame=bounds;
    self.borderMaskLayer.path=path.CGPath;
    
    CGRect bufferRect = CGRectMake(0,
                                   0,
                                   CGRectGetWidth(bounds)*self.bufferProgress,
                                   CGRectGetHeight(bounds));
    UIBezierPath *bufferPath = [UIBezierPath bezierPathWithRect:bufferRect];
    self.fillLayer.path = bufferPath.CGPath;
    self.borderLayer.frame = bounds;
    self.fillLayer.frame = bounds;
    self.fillMaskLayer.frame = bounds;
    self.fillMaskLayer.path = path.CGPath;
    CGRect playerRect = CGRectMake(0,
                                   0,
                                   CGRectGetWidth(bounds)*self.elapsedProgress,
                                   CGRectGetHeight(bounds));
    UIBezierPath *playerPath = [UIBezierPath bezierPathWithRect:playerRect];
    self.coverLayer.path=playerPath.CGPath;
    self.coverLayer.frame=bounds;
    self.coverMaskLayer.frame = bounds;
    self.coverMaskLayer.path = playerPath.CGPath;
}
@end

