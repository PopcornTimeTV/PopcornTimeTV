//
//  ZKDefs.h
//  ZipKit
//
//  Created by Karl Moskowski on 01/04/09.
//

#import <Foundation/Foundation.h>

#define ZK_TARGET_OS_MAC (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
#define ZK_TARGET_OS_IPHONE (TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || TARGET_OS_IPHONE_SIMULATOR)

enum ZKReturnCodes {
	zkFailed = -1,
	zkCancelled = 0,
	zkSucceeded = 1,
};

// File & path naming
extern NSString *const ZKArchiveFileExtension;
extern NSString *const ZKMacOSXDirectory;
extern NSString *const ZKDotUnderscore;
extern NSString *const ZKExpansionDirectoryName;

// Keys for dictionary passed to size calculation thread
extern NSString *const ZKPathsKey;
extern NSString *const ZKusingResourceForkKey;

// Keys for dictionary returned from ZKDataArchive inflation
extern NSString *const ZKFileDataKey;
extern NSString *const ZKFileAttributesKey;
extern NSString *const ZKPathKey;

// Zipping & Unzipping
extern const unsigned long long ZKZipBlockSize;
extern const UInt32 ZKNotificationIterations;

// Magic numbers and lengths for zip records
extern const UInt32 ZKCDHeaderMagicNumber;
extern const UInt32 ZKCDHeaderFixedDataLength;

extern const UInt32 ZKCDTrailerMagicNumber;
extern const UInt32 ZKCDTrailerFixedDataLength;

extern const UInt32 ZKLFHeaderMagicNumber;
extern const UInt32 ZKLFHeaderFixedDataLength;

extern const UInt32 ZKCDTrailer64MagicNumber;
extern const UInt32 ZKCDTrailer64FixedDataLength;

extern const UInt32 ZKCDTrailer64LocatorMagicNumber;
extern const UInt32 ZKCDTrailer64LocatorFixedDataLength;
