

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VLCSiriRemoteTouchLocation){
    VLCSiriRemoteTouchLocationUnknown,
    VLCSiriRemoteTouchLocationLeft,
    VLCSiriRemoteTouchLocationRight,
};

@interface VLCSiriRemoteGestureRecognizer: UIGestureRecognizer
@property (nonatomic) NSTimeInterval minimumLongPressDuration;
@property (nonatomic) NSTimeInterval minimumLongTapDuration;
@property (nonatomic, readonly, getter=isLongPress) BOOL longPress;
@property (nonatomic, readonly, getter=isLongTap) BOOL longTap;

@property (nonatomic, getter=isClick) BOOL click;
@property (nonatomic, readonly) VLCSiriRemoteTouchLocation touchLocation;

- (nonnull instancetype)initWithTarget:(nullable id)target action:(nullable SEL)action;

@end

