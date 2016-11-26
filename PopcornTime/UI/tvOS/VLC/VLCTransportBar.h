

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, VLCTransportBarHint) {
    VLCTransportBarHintNone,
    VLCTransportBarHintPaused,
    VLCTransportBarHintScanForward,
    VLCTransportBarHintJumpForward10,
    VLCTransportBarHintJumpBackward10,
};

IB_DESIGNABLE @interface VLCTransportBar : UIView
@property (nonatomic) IBInspectable CGFloat progress;
@property (nonatomic) IBInspectable CGFloat scrubbingProgress;
@property (nonatomic) IBInspectable CGFloat bufferProgress;
@property (nonatomic) IBInspectable UIImage *screenshot;
@property (nonatomic, getter=isScrubbing) IBInspectable BOOL scrubbing;
@property (nonatomic, getter=isBuffering) IBInspectable BOOL buffering;

@property (nonatomic, readonly) UILabel *elapsedTimeLabel;
@property (nonatomic, readonly) UILabel *remainingTimeLabel;
@property (nonatomic, readonly) UILabel *scrubbingTimeLabel;

@property (nonatomic) VLCTransportBarHint hint;

@end

NS_ASSUME_NONNULL_END
