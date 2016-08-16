//
//  NSString+ZKAdditions.h
//  ZipKit
//
//  Created by Karl Moskowski on 01/04/09.
//

#import <Foundation/Foundation.h>

@interface NSString (ZKAdditions)

- (UInt32)	zk_precomposedUTF8Length;
- (BOOL)	zk_isResourceForkPath;

@end