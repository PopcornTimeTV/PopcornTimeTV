

#import <Foundation/Foundation.h>

@interface NSObject (Swift_Observer)

- (BOOL)remove:(NSObject * _Nonnull)observer for:(NSString * _Nonnull)keyPath in:(void * _Nullable)context with:(NSError * _Nullable * _Nullable)error;

@end
