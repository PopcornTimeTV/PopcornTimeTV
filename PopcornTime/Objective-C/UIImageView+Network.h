

#import <UIKit/UIKit.h>

@interface UIImageView (Network)

@property (nonatomic, copy) NSURL *imageURL;

- (void)loadImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;

@end
