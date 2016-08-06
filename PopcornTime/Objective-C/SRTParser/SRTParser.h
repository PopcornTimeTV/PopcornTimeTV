

#import <Foundation/Foundation.h>
#import "SRTSubtitle.h"

typedef NS_ENUM(NSInteger, SRTParserError) {
    SDSRTMissingIndexError,
    SDSRTCarriageReturnIndexError,
    SDSRTInvalidTimeError,
    SDSRTMissingTimeError,
    SDSRTMissingTimeBoundariesError
};

@interface SRTParser: NSObject

@property (nonatomic, copy) NSArray *subtitles;

- (NSArray *)parseString:(NSString *)string error:(NSError **)error;

@end
