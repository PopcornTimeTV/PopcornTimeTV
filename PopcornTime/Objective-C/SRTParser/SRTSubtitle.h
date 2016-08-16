

#import <Foundation/Foundation.h>

@interface SRTSubtitle : NSObject

@property (nonatomic, assign, readonly) NSUInteger index;
@property (nonatomic, assign, readonly) NSTimeInterval startTime;
@property (nonatomic, assign, readonly) NSTimeInterval endTime;
@property (nonatomic, copy, readonly) NSString *content;

- (id)initWithIndex:(NSUInteger)index startTime:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime content:(NSString *)content;

@end
