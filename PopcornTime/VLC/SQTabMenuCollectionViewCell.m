

#import "SQTabMenuCollectionViewCell.h"

@implementation SQTabMenuCollectionViewCell

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator{
    
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    
    if (self == context.nextFocusedView) {
        
        [self.delegate newItemSelected:self];
        /*
        UIInterpolatingMotionEffect *focusEffectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        focusEffectX.minimumRelativeValue = @(-11);
        focusEffectX.maximumRelativeValue = @(11);
        [self.followingTag addMotionEffect:focusEffectX];
        
        UIInterpolatingMotionEffect *focusEffectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        focusEffectY.minimumRelativeValue = @(-13);
        focusEffectY.maximumRelativeValue = @(13);
        [self.followingTag addMotionEffect:focusEffectY];
        
        self.topfollowingTagConstraint.constant   = -35.0;
        self.rightfollowingTagConstraint.constant = -25.0;
        
        [coordinator addCoordinatedAnimations:^{
            [self layoutIfNeeded];
        }
                                   completion:^{

                                   }];
         */
        
    }
    else if (self == context.previouslyFocusedView) {
        /*
        NSArray *motionEffects = [self.followingTag motionEffects];
        
        if ([motionEffects count] > 0) {
            for (NSInteger i = [motionEffects count]-1 ; i >= 0; i--) {
                UIInterpolatingMotionEffect *focusEffect = motionEffects[i];
                [self.followingTag removeMotionEffect:focusEffect];
            }
        }
        
        self.topfollowingTagConstraint.constant   = .0;
        self.rightfollowingTagConstraint.constant = .0;
        
        [coordinator addCoordinatedAnimations:^{
            [self layoutIfNeeded];
        }
                                   completion:^{
                                       
                                   }];
         */
    }
    
}

@end
