

#import <Foundation/Foundation.h>

@interface SubtitleManager : NSObject

+ (instancetype)sharedManager;

- (void)fetchSubtitlesForIMDB:(NSString *)imdbID completion:(void (^)(NSArray *subtitles))completionHandler;

@end
