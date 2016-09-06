
#import <UIKit/UIKit.h>
#import "SQTabMenuCollectionViewCell.h"
#import "VLCTransportBar.h"
#import "VLCFrostedGlasView.h"
@protocol SYVLCPlayerViewControllerDelegate <NSObject>

- (void) setRatio:(float) ratio;
- (float) currentRatio;

@end

@class SYLoadingProgressView;


@interface SYVLCPlayerViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet VLCTransportBar *transportBar;
@property (weak, nonatomic) IBOutlet VLCFrostedGlasView *osdView;

@property (nonatomic, weak) IBOutlet UIView *topButtonContainerView;

@property (weak, nonatomic) IBOutlet UILabel *videoTitle;
@property (nonatomic, weak) IBOutlet UIView *swipeMesaggeContainerView;
@property (nonatomic, weak) IBOutlet UILabel *swipeMesaggeLabel;

@property (nonatomic, weak) IBOutlet UIImageView *loadingLogo;

// Focus
@property (nonatomic, weak) IBOutlet UIView *topMenuContainerView;
//@property (nonatomic, weak) IBOutlet UIButton *middleButton;
@property (nonatomic, weak) IBOutlet UIButton *topButton;
@property (nonatomic, weak) IBOutlet UIButton *subValueDelayButton;

@property (nonatomic, weak) IBOutlet UICollectionView *subTabBarCollectionView;
@property (nonatomic, weak) IBOutlet UICollectionView *audioTabBarCollectionView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topTopMenuSpace;


@property (nonatomic, weak) IBOutlet UIButton *subsButton;
@property (nonatomic, weak) IBOutlet UIButton *subsDelayButton;
@property (nonatomic, weak) IBOutlet UIButton *audioButton;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *middleSubsConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *middleAudioConstraint;


@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *indicatorView;

@property (nonatomic, assign) float initialRatio;
@property (nonatomic, assign) BOOL isFile;
@property (nonatomic, assign) float currentSubTitleDelay;
@property (nonatomic, weak)   UIViewController <SYVLCPlayerViewControllerDelegate> *rootViewController;
@property (nonatomic, weak) id <SQTabMenuCollectionViewCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIView *loadingView;
@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *percentLabel;
@property (nonatomic, weak) IBOutlet UILabel *statsLabel;


- (id)initWithVideoInfo:(NSDictionary *)videoInfo;
- (id) initWithURL:(NSURL *) url imdbID:(NSString *) hash subtitles:(NSArray *)cahcedSubtitles;

@end
