

#import "NSObject+Swift_Observer.h"

@implementation NSObject (Swift_Observer)

- (BOOL)remove:(NSObject * _Nonnull)observer for:(NSString * _Nonnull)keyPath in:(void * _Nullable)context with:(NSError* * _Nullable)error {
    @try {
        [self removeObserver:observer forKeyPath:keyPath context:context];
    } @catch (NSException *exception) {
        *error = [[NSError alloc]initWithDomain:@"com.popcorntimetv.popcorntime.error" code:-12 userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
        return NO;
    }
    return YES;
}

@end
