

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface VLCBufferingBar : UIView
@property (nonatomic) CGFloat bufferProgress;
@property (nonatomic) CGFloat elapsedProgress;

@property (nonatomic) UIColor *bufferColor;
@property (nonatomic) UIColor *borderColor;
@property (nonatomic) UIColor *elapsedColor;
@end
NS_ASSUME_NONNULL_END
