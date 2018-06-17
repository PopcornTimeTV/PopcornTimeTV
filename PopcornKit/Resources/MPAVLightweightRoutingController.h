#import <Foundation/Foundation.h>
#import "MPAVLightweightRoutingControllerDelegate.h"

@class MPAVRoute;

NS_ASSUME_NONNULL_BEGIN
/**
 Class for iOS 11.4 to discover Airplay devices
 */
@interface MPAVLightweightRoutingController : NSObject

@property(readonly, copy, nonatomic) NSString *name; 
@property(nonatomic) long long discoveryMode;
@property(readonly, nonatomic) NSArray<MPAVRoute *> *pickedRoutes;
@property(readonly, nonatomic, getter=isDevicePresenceDetected) _Bool devicePresenceDetected;
- (id)description;

@end

NS_ASSUME_NONNULL_END
