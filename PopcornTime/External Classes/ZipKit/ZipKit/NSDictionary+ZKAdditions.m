//
//  NSDictionary+ZKAdditions.m
//  ZipKit
//
//  Created by Karl Moskowski on 01/04/09.
//

#import "NSDictionary+ZKAdditions.h"

NSString *const ZKTotalFileSize = @"ZKTotalFileSize";
NSString *const ZKItemCount = @"ZKItemCount";

@implementation NSDictionary (ZKAdditions)

+ (NSDictionary *) zk_totalSizeAndCountDictionaryWithSize:(UInt64)size andItemCount:(UInt64)count {
	return @{ ZKTotalFileSize: @(size), ZKItemCount: @(count) };
}

- (UInt64) zk_totalFileSize {
	return [self[ZKTotalFileSize] unsignedLongLongValue];
}

- (UInt64) zk_itemCount {
	return [self[ZKItemCount] unsignedLongLongValue];
}

@end