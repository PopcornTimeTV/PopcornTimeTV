

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VLCSiriRemoteTouchLocation){
    VLCSiriRemoteTouchLocationUnknown,
    VLCSiriRemoteTouchLocationLeft,
    VLCSiriRemoteTouchLocationRight,
};

@interface VLCSiriRemoteGestureRecognizer : UIGestureRecognizer
@property (nonatomic) NSTimeInterval minLongPressDuration; // default = 0.5
@property (nonatomic, readonly, getter=isLongPress) BOOL longPress;
@property (nonatomic, getter=isClick) BOOL click;
@property (nonatomic, readonly) VLCSiriRemoteTouchLocation touchLocation;

@end

