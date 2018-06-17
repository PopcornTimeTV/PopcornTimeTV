#import <Foundation/Foundation.h>

@class MPAVLightweightRoutingController, MPAVRoute;

@protocol MPAVLightweightRoutingControllerDelegate <NSObject>

@optional
- (void)lightweightRoutingController:(MPAVLightweightRoutingController *)controller didChangePickedRoutes:(NSArray<MPAVRoute*> *)routes;
- (void)lightweightRoutingController:(MPAVLightweightRoutingController *)controller didChangeDevicePresenceDetected:(BOOL)arg2;
@end
