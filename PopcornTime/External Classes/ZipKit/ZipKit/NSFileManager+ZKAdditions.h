//
//  NSFileManager+ZKAdditions.h
//  ZipKit
//
//  Created by Karl Moskowski on 01/04/09.
//

#import <Foundation/Foundation.h>
#import "ZKDefs.h"

@interface NSFileManager (ZKAdditions)

- (BOOL) zk_isSymLinkAtPath:(NSString *)path;
- (BOOL) zk_isDirAtPath:(NSString *)path;

- (UInt64) zk_dataSizeAtFilePath:(NSString *)path;
- (NSDictionary *) zkTotalSizeAndItemCountAtPath:(NSString *)path usingResourceFork:(BOOL)rfFlag;
#if ZK_TARGET_OS_MAC
- (void) zk_combineAppleDoubleInDirectory:(NSString *)path;
#endif

- (NSDate *) zk_modificationDateForPath:(NSString *)path;
- (UInt32) zk_posixPermissionsAtPath:(NSString *)path;
- (UInt32) zk_externalFileAttributesAtPath:(NSString *)path;
- (UInt32) zk_externalFileAttributesFor:(NSDictionary *)fileAttributes;

- (UInt32) zk_crcForPath:(NSString *)path;
- (UInt32) zk_crcForPath:(NSString *)path invoker:(id)invoker;
- (UInt32) zk_crcForPath:(NSString *)path invoker:(id)invoker throttleThreadSleepTime:(NSTimeInterval)throttleThreadSleepTime;

@end