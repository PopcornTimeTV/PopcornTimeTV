

#import <Foundation/Foundation.h>
#import "MPAVRoutingControllerDelegate.h"

@class MPAVRoute;

NS_ASSUME_NONNULL_BEGIN

/**
 This class is used to discover AirPlay devices.
 */
@interface MPAVRoutingController : NSObject

/// Array of available AirPlay routes.
@property (nonatomic, readonly, copy) NSArray<MPAVRoute*> *availableRoutes;

/// The category the route falls under.
@property (nonatomic, copy) NSString *category;

/// The delegate for recieving `MediaPlayer.framework` notifications.
@property (nonatomic, nullable, weak) id <MPAVRoutingControllerDelegate> delegate;

/// The discovery mode of the device.
@property (nonatomic) int discoveryMode;

/// The type of the screen currently being mirrored to.
@property (nonatomic, readonly) int externalScreenType;

/// The name of the controller
@property (nonatomic, copy) NSString *name;

/// The route that is currently being connected to.
@property (nonatomic, readonly, nullable) MPAVRoute *pendingPickedRoute;

/// The current route that the device is mirroring to.
@property (nonatomic, readonly, nullable) MPAVRoute *pickedRoute;
@property (nonatomic, readonly) BOOL volumeControlIsAvailable;


/**
 Clear the currently cached routes, if any.
 */
- (void)clearCachedRoutes;

/**
 Scan for new AirPlay devices.
 
 @param completion  The completion handler for the request.
 */
- (void)fetchAvailableRoutesWithCompletionHandler:(void (^)(NSArray<MPAVRoute*> *))completion;

/**
 Automatically select and connect to the best route based upon connection status.
 
 @return    If a route was found and connected to.
 */
- (BOOL)pickBestDeviceRoute;

/**
 Automatically select and connect to the first handset route found.
 
 @return    If a handset route was found and connected to.
 */
- (BOOL)pickHandsetRoute;

/**
 Connect to a route.
 
 @param route   The route to be connected to.
 
 @return    If the route was successfully connected to.
 */
- (BOOL)pickRoute:(MPAVRoute *)route;

/**
 Connect to a route that is password protected.
 
 @param route           The route to be connected to.
 @param password        The password for the route.
 
 @return    If the password was correct and the route was successfully connected to.
 */
- (BOOL)pickRoute:(MPAVRoute *)route withPassword:(NSString *)password;

/**
 Automatically select and connect to the first speaker route found.
 
 @return    If a speaker route was found and connected to.
 */
- (BOOL)pickSpeakerRoute;

/**
 Searches for routes that are AirPlay recievers.
 
 @return    If the route that the device currently connected to is an AirPlay reciever.
 */
- (BOOL)receiverRouteIsPicked;

/**
 Searches for routes that are AirTunes speakers.
 
 @return    If the route that the device currently connected to is an AirTunes speaker.
 */
- (BOOL)airtunesRouteIsPicked;

/**
 Searches for routes that are wireless displays.
 
 @return    If the route that the device currently connected to is a wireless display - eg. AppleTV.
 */
- (BOOL)wirelessDisplayRouteIsPicked;

/**
 Searches for routes that are handsets.
 
 @return    If the route that the device currently connected to is a handset.
 */
- (BOOL)handsetRouteIsPicked;

/**
 Searches for routes that are speakers.
 
 @return    If the route that the device currently connected to is a speaker.
 */
- (BOOL)speakerRouteIsPicked;

/**
 Searches for routes that are not handsets or generic speakers.
 
 @return    If routes are available that do not fall under the handsets or generic speakers category.
 */
- (BOOL)routeOtherThanHandsetAndSpeakerAvailable;

/**
 Searches for routes that are not handsets.
 
 @return    If routes are available that do not fall under the handsets category.
 */
- (BOOL)routeOtherThanHandsetAvailable;

/**
 Change the category of the controller to something else.
 
 @param category    The new category for the controller.
 */
- (void)setCategory:(NSString *)category;

/**
 Set's the delegate for the current routing controller.
 
 @param delegate    The object that wishes to recieve delegate notifications.
 */
- (void)setDelegate:(id <MPAVRoutingControllerDelegate>)delegate;

/**
 Change the current device's discovery mode.
 
 @param rawValue    The rawValue from the `DiscoveryMode` enum.
 */
- (void)setDiscoveryMode:(int)rawValue;

/**
 Changes the name of the current controller.
 
 @param name    The new name of the controller.
 */
- (void)setName:(NSString *)name;

/**
 Disconnect from the video route of the AirPlay route. Audio route will still stay connected.
 
 @param completion  Completion handler called upon request completion. Contains an optional error value indicating the requests status.
 */
- (void)unpickAirPlayScreenRouteWithCompletion:(void (^)(NSError * _Nullable))completion;

/**
 The video route for the correspoding route. Will return `nil` if the route is an audio only device.
 
 @param route   The route that the video route is to be fetched for.
 
 @return A video route or `nil`.
 */
- (nullable MPAVRoute *)videoRouteForRoute:(MPAVRoute *)route;

@end

NS_ASSUME_NONNULL_END
