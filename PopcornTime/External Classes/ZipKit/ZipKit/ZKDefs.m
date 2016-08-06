//
//  ZKDefs.m
//  ZipKit
//
//  Created by Karl Moskowski on 01/04/09.
//

#import "ZKDefs.h"

NSString *const ZKArchiveFileExtension = @"zip";
NSString *const ZKMacOSXDirectory = @"__MACOSX";
NSString *const ZKDotUnderscore = @"._";
NSString *const ZKExpansionDirectoryName = @".ZipKit";

NSString *const ZKPathsKey = @"paths";
NSString *const ZKusingResourceForkKey = @"usingResourceFork";

NSString *const ZKFileDataKey = @"fileData";
NSString *const ZKFileAttributesKey = @"fileAttributes";
NSString *const ZKPathKey = @"path";

const unsigned long long ZKZipBlockSize = 262144;
const UInt32 ZKNotificationIterations = 100;

const UInt32 ZKCDHeaderMagicNumber = 0x02014B50;
const UInt32 ZKCDHeaderFixedDataLength = 46;

const UInt32 ZKCDTrailerMagicNumber = 0x06054B50;
const UInt32 ZKCDTrailerFixedDataLength = 22;

const UInt32 ZKLFHeaderMagicNumber = 0x04034B50;
const UInt32 ZKLFHeaderFixedDataLength = 30;

const UInt32 ZKCDTrailer64MagicNumber = 0x06064b50;
const UInt32 ZKCDTrailer64FixedDataLength = 56;

const UInt32 ZKCDTrailer64LocatorMagicNumber = 0x07064b50;
const UInt32 ZKCDTrailer64LocatorFixedDataLength = 20;
