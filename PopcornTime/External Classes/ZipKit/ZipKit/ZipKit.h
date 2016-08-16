//
//  ZipKit.h
//  ZipKit
//
//  Created by Sam Deane on 25/10/13.
//

#import "ZKArchive.h"
#import "ZKDataArchive.h"
#import "ZKDefs.h"
#import "ZKFileArchive.h"
#import "ZKLog.h"

#import "NSData+ZKAdditions.h"
#import "NSDate+ZKAdditions.h"
#import "NSDictionary+ZKAdditions.h"
#import "NSFileHandle+ZKAdditions.h"
#import "NSFileManager+ZKAdditions.h"
#import "NSString+ZKAdditions.h"

#if ZK_TARGET_OS_MAC
#import "GMAppleDouble.h"
#import "GMAppleDouble+ZKAdditions.h"
#endif