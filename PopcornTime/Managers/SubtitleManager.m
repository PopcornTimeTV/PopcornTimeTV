

#import "SubtitleManager.h"

@implementation SubtitleManager

+ (instancetype)sharedManager {
    __strong static id sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true);
        NSString *cachcesDirectory = [paths.firstObject stringByAppendingPathComponent:@"Subtitles"];
        [[NSFileManager defaultManager] createDirectoryAtPath:cachcesDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return self;
}

- (void)fetchSubtitlesForIMDB:(NSString *)imdbID completion:(void (^)(NSArray *subtitles))completionHandler {
//    NSString *endpoint = @"http://api.yifysubtitles.com/subs/%@", imdbID;
}

@end
