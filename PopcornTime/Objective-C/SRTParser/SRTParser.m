

#import "SRTParser.h"

@implementation SRTParser

- (NSArray *)parseString:(NSString *)string error:(NSError **)error {
    NSString *newString = [string stringByReplacingOccurrencesOfString:@"\n\r\n" withString:@"\n\n"];
    newString = [newString stringByReplacingOccurrencesOfString:@"\n\n\n" withString:@"\n\n"];
    NSArray *textBlocks = [newString componentsSeparatedByString:@"\n\n"];
    //if you are going to do it at least do it properly!!!
    newString = [newString stringByReplacingOccurrencesOfString:@"<b>" withString:@""];
    newString = [newString stringByReplacingOccurrencesOfString:@"</b>" withString:@""];
    newString = [newString stringByReplacingOccurrencesOfString:@"<i>" withString:@""];
    newString = [newString stringByReplacingOccurrencesOfString:@"</i>" withString:@""];
    newString = [newString stringByReplacingOccurrencesOfString:@"<u>" withString:@""];
    newString = [newString stringByReplacingOccurrencesOfString:@"</u>" withString:@""];
    newString = [newString stringByReplacingOccurrencesOfString:@"{y:i}" withString:@""];
    
    NSMutableArray *subtitles = [[NSMutableArray alloc] init];
    
    for (NSString *item in textBlocks) {
        SRTSubtitle *subtitle = [self parseString:item];
        if (subtitle) {
            [subtitles addObject:subtitle];
        }
    }
    
    return subtitles;
}

- (SRTSubtitle *)parseString:(NSString *)text {
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    
    if ([lines count] >= 3) {
        NSInteger index = [lines[0] integerValue];
        
        NSTimeInterval startTime;
        NSTimeInterval endTime;
        
        NSArray *timeRange = [lines[1] componentsSeparatedByString:@"-->"];
        // there will always be 2 items in time range
        if ([timeRange count] == 2) {
            NSString *startTimeString = [timeRange[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *endTimeString = [timeRange[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            startTime = [self timeIntervalFromSubRipTimeString:startTimeString];// + self.timeOffset;
            endTime = [self timeIntervalFromSubRipTimeString:endTimeString];// + self.timeOffset;
        } else {
            return nil;
        }
        
        NSMutableString *text = [NSMutableString string];
        for (int i=2; i<[lines count]; i++) {
            [text appendFormat:@"%@", lines[i]];
            if (i == 3) {
                [text appendFormat:@"\n"];
            }
        }
        
        NSString *content = [text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        content = [self stringByStrippingHTML:content];
        content = [content stringByReplacingOccurrencesOfString:@"<b>" withString:@""];
        content = [content stringByReplacingOccurrencesOfString:@"</b>" withString:@""];
        content = [content stringByReplacingOccurrencesOfString:@"<i>" withString:@""];
        content = [content stringByReplacingOccurrencesOfString:@"</i>" withString:@""];
        content = [content stringByReplacingOccurrencesOfString:@"<u>" withString:@""];
        content = [content stringByReplacingOccurrencesOfString:@"</u>" withString:@""];
        content = [content stringByReplacingOccurrencesOfString:@"{y:i}" withString:@""];
        
        return [[SRTSubtitle alloc] initWithIndex:index startTime:startTime endTime:endTime content:content];
    } else {
        return nil;
    }
}

- (NSString *)stringByStrippingHTML:(NSString *)string {
    NSRange r;
    while ((r = [string rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        string = [string stringByReplacingCharactersInRange:r withString:@""];
    return string;
}

- (NSTimeInterval)timeIntervalFromSubRipTimeString:(NSString *)text {
    NSArray *components = [text componentsSeparatedByString:@","];
    int miliseconds = 0;
    if ([components count]==2) miliseconds = [components[1] intValue];
    
    NSArray *hourMinSec = [components[0] componentsSeparatedByString:@":"];
    int hour = [hourMinSec[0] intValue];
    int minute = [hourMinSec[1] intValue];
    int second = [hourMinSec[2] intValue];
    
    NSTimeInterval timeInterval = hour * 60 * 60 + minute * 60 + second + miliseconds / 1000.0;
    return timeInterval;
}

+ (NSTimeInterval)scanTime:(NSScanner *)scanner {
    NSInteger hours, minutes, seconds, milliseconds;
    if (![scanner scanInteger:&hours]) return -1;
    if (![scanner scanString:@":" intoString:NULL]) return -1;
    if (![scanner scanInteger:&minutes]) return -1;
    if (![scanner scanString:@":" intoString:NULL]) return -1;
    if (![scanner scanInteger:&seconds]) return -1;
    if (![scanner scanString:@"," intoString:NULL]) return -1;
    if (![scanner scanInteger:&milliseconds]) return -1;

    if (hours < 0  || minutes < 0  || seconds <  0 || milliseconds < 0 ||
        hours > 60 || minutes > 60 || seconds > 60 || milliseconds > 999)
    {
        return -1;
    }

    return (hours * 60 * 60) + (minutes * 60) + seconds + (milliseconds / 1000.0);
}

+ (NSError *)errorWithDescription:(NSString *)description type:(SRTParserError)type line:(NSUInteger)line {
    description = [description stringByAppendingFormat:@" at %d line", (uint)line + 1];
    return [NSError errorWithDomain:@"SRTParser" code:type userInfo:@
    {
        NSLocalizedDescriptionKey: description,
        @"line": @(line)
    }];
}

@end
