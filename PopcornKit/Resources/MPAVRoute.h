
#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/**
 This class describes AirPlay devices.
 */
@interface MPAVRoute: NSObject

#pragma mark - Route types

/// If the route is a pair of `Apple AirPods`.
@property (getter=isAirpodsRoute, nonatomic, readonly) BOOL airpodsRoute;

/// If the route is a pair of `Beats Solo` headphones.
@property (getter=isBeatsSoloRoute, nonatomic, readonly) BOOL beatsSoloRoute;

/// If the route is a pair of `Beats X` earphones.
@property (getter=isBeatsXRoute, nonatomic, readonly) BOOL beatsXRoute;

/// If the route is a pair of `Beats Powerbeats` earphones.
@property (getter=isPowerbeatsRoute, nonatomic, readonly) BOOL powerbeatsRoute;

/// If the route is a device, ie. an iPhone, iPad, iPod or an Apple TV.
@property (nonatomic, readonly) BOOL isDeviceRoute;

/// If the route has an option to mirror the devices display to it, a corresponding route will be returned, otherwise `nil`.
@property (nonatomic, readonly, nullable) MPAVRoute *wirelessDisplayRoute;



/// If the `wirelessDisplayRoute` is selected.
@property (nonatomic, readonly) BOOL displayIsPicked;

/// If the route is picked.
@property (getter=isPicked, nonatomic, readonly) BOOL picked;


/// An array of audio devices currently connected to the device.
@property (nonatomic, readonly, nullable) NSArray *auxiliaryDevices;

#pragma mark - Types

/// The type of the routes `wirelessDisplayRoute` property.
@property (nonatomic, readonly) int displayRouteType;

/// The type of the password on the current route.
@property (nonatomic, readonly) int passwordType;

/// The type of the...
@property (nonatomic, readonly) int pickableRouteType;

/// The type of the route.
@property (nonatomic, readonly) int routeType;

/// The subtype of the route.
@property (nonatomic, readonly) int routeSubtype;



/// If the route is...
@property (getter=isPickedOnPairedDevice, nonatomic, readonly) BOOL pickedOnPairedDevice;

/// If audio or video is playing on the route.
@property (getter=isPlayingOnPairedDevice, nonatomic, readonly) BOOL playingOnPairedDevice;

/// If the route requires a password to be connected to.
@property (nonatomic, readonly) BOOL requiresPassword;

/// The name of the route
@property (nonatomic, readonly) NSString *routeName;

/// A unique id for the current route (it's MAC address).
@property (nonatomic, readonly) NSString *routeUID;


/// Detailed information about the route.
- (NSString *)avRouteDescription;

#pragma mark - Setters

/**
 Setter method for the `displayRouteType` enum.
 
 @param rawValue    The rawValue of the `displayRouteType` enum.
 */
- (void)setDisplayRouteType:(int)rawValue;

/**
 Boolean value determining whether the current route is being streamed to or not.
 
 @param picked  Pass `YES` to connect to the current route, and `NO` to disconnect from the current route, if connected to.
 */
- (void)setPicked:(BOOL)picked;

/**
 Changes the name of the current route.
 
 @param name    Set the `routeName` property to a custom string.
 */
- (void)setRouteName:(NSString *)name;

/**
 Change the wireless display route to any custom display route.
 
 @param route   Set the `wirelessDisplayRoute` property to a custom route.
 */
- (void)setWirelessDisplayRoute:(MPAVRoute *)route;

@end

NS_ASSUME_NONNULL_END
