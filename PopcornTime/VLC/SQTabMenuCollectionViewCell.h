

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SQTabMenuCollectionViewType) {
    SQTabMenuCollectionViewTypeUnknown       = -1,
    SQTabMenuCollectionViewTypeSubtitle      = 0,
    SQTabMenuCollectionViewTypeAudio         = 1,
    SQTabMenuCollectionViewTypeSubColor      = 2,
    SQTabMenuCollectionViewTypeSubFont       = 3,
    SQTabMenuCollectionViewTypeSubBackground = 4
};


@protocol SQTabMenuCollectionViewCellDelegate <NSObject>

- (void) newItemSelected:(id) cell;

@end


@interface SQTabMenuCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) id <SQTabMenuCollectionViewCellDelegate> delegate;
@property (nonatomic, assign) SQTabMenuCollectionViewType collectionViewType;

@end
