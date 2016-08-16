//
//  NSString+ZKAdditions.m
//  ZipKit
//
//  Created by Karl Moskowski on 01/04/09.
//

#import "NSString+ZKAdditions.h"
#import "ZKDefs.h"

@implementation NSString (ZKAdditions)

- (UInt32) zk_precomposedUTF8Length {
	return (UInt32)[[self precomposedStringWithCanonicalMapping] lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL) zk_isResourceForkPath {
	return [[self pathComponents][0] isEqualToString:ZKMacOSXDirectory];
}


@end
