
#import <Foundation/Foundation.h>

@class MPAVRoutingController, MPAVRoute;

/**
 This protocol can provide information about AirPlay connection status.
 */
@protocol MPAVRoutingControllerDelegate <NSObject>

@optional
    
/**
 Called when a route that a user selected to connect to was unavailable for connection or the user canceled the request.
     
 @param controller  The controller managing the route that was to be connected to.
 @param error       Reason why the route failed to connect.
 */
- (void)routingController:(MPAVRoutingController *)controller didFailToPickRouteWithError:(NSError *)error;

/**
 Called when a route that a user selected to connect to was successfully connected to.
     
 @param controller  The controller managing the route that was connected to.
 @param newRoute    The route that was connected to.
     */
- (void)routingController:(MPAVRoutingController *)controller pickedRouteDidChange:(MPAVRoute *)newRoute;

/**
 Called when the available AirPlay devices changes.
     
 @param controller  The controller managing the available routes.
*/
- (void)routingControllerAvailableRoutesDidChange:(MPAVRoutingController *)controller;

/**
 Called when the route controller loses focus while connecting; eg. When the selected route has a password and an alert controller is presented over-top of the route controller.
     
 @param controller  The controller managing the available routes.
 */
- (void)routingControllerDidPauseFromActiveRouteChange:(MPAVRoutingController *)controller;

/**
 Called when the device starts or stops mirroring to a route.
    
 @param controller  The controller managing the route.
*/
- (void)routingControllerExternalScreenTypeDidChange:(MPAVRoutingController *)controller;

@end
