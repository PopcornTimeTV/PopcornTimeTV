

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This class is used to discover Audio-only AirPlay devices.
 */
@interface MPAudioDeviceController : NSObject

/// If the current device is searching for AirPlay devices. This must be enabled or AirPlay devices will not show up.
@property (nonatomic) BOOL routeDiscoveryEnabled;

/**
 Fetch detailed information about a route based upon it's index in the available routes array.
 
 @param index   The position of the route in the available routes array.
 
 @return    Dictionary with detailed, useful information about the specified route.
 */
- (NSDictionary<NSString*, id> *)routeDescriptionAtIndex:(int)index;

@end

NS_ASSUME_NONNULL_END
