//
//  ZKArchive.m
//  ZipKit
//
//  Created by Karl Moskowski on 08/05/09.
//

#import "ZKArchive.h"
#import "NSDictionary+ZKAdditions.h"
#import "NSFileManager+ZKAdditions.h"
#import "ZKCDTrailer.h"
#import "ZKDefs.h"

#pragma mark -

@implementation ZKArchive

#pragma mark -
#pragma mark Utility

+ (BOOL) validArchiveAtPath:(NSString *)path {
	// check that the first few bytes of the file are a local file header
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	NSData *fileHeader = [fileHandle readDataOfLength:4];
	[fileHandle closeFile];
	UInt32 headerValue;
//	[fileHeader getBytes:&headerValue];
    [fileHeader getBytes:&headerValue length:4];
	return CFSwapInt32LittleToHost(headerValue) == ZKLFHeaderMagicNumber;
}

+ (NSString *) uniquify:(NSString *)path {
	// avoid name collisions by adding a sequence number if needed
	NSString *uniquePath = [NSString stringWithString:path];
	NSString *dir = [path stringByDeletingLastPathComponent];
	NSString *fileNameBase = [[path lastPathComponent] stringByDeletingPathExtension];
	NSString *ext = [path pathExtension];
	NSUInteger i = 2;
	NSFileManager *fm = [NSFileManager new];
	while ([fm fileExistsAtPath:uniquePath]) {
		uniquePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %lu", fileNameBase, (unsigned long)i++]];
		if (ext && [ext length] > 0)
			uniquePath = [uniquePath stringByAppendingPathExtension:ext];
	}
	return uniquePath;
}

- (void) calculateSizeAndItemCount:(NSDictionary *)userInfo {
	NSArray *paths = userInfo[ZKPathsKey];
	BOOL rfFlag = [userInfo[ZKusingResourceForkKey] boolValue];
	unsigned long long size = 0;
	unsigned long long count = 0;
	NSFileManager *fmgr = [NSFileManager new];
	NSDictionary *dict = nil;
	for (NSString *path in paths) {
		dict = [fmgr zkTotalSizeAndItemCountAtPath:path usingResourceFork:rfFlag];
		size += [dict zk_totalFileSize];
		count += [dict zk_itemCount];
	}
	[self performSelectorOnMainThread:@selector(didUpdateTotalSize:)
                           withObject:@(size) waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(didUpdateTotalCount:)
                           withObject:@(count) waitUntilDone:NO];
}

- (NSString *) uniqueExpansionDirectoryIn:(NSString *)enclosingFolder {
	NSString *expansionDirectory = [enclosingFolder stringByAppendingPathComponent:ZKExpansionDirectoryName];
	NSUInteger i = 1;
	while ([self.fileManager fileExistsAtPath:expansionDirectory])
		expansionDirectory = [enclosingFolder stringByAppendingPathComponent:
		                      [NSString stringWithFormat:@"%@ %lu", ZKExpansionDirectoryName, (unsigned long)i++]];
	return expansionDirectory;
}

- (void) cleanUpExpansionDirectory:(NSString *)expansionDirectory {
	NSString *enclosingFolder = [expansionDirectory stringByDeletingLastPathComponent];
	NSArray *dirContents = [self.fileManager contentsOfDirectoryAtPath:expansionDirectory error:nil];
	for (NSString *item in dirContents) {
		if (![item isEqualToString:ZKMacOSXDirectory]) {
			NSString *subPath = [expansionDirectory stringByAppendingPathComponent:item];
			NSString *dest = [enclosingFolder stringByAppendingPathComponent:item];
			NSUInteger i = 2;
			while ([self.fileManager fileExistsAtPath:dest]) {
				NSString *ext = [item pathExtension];
				dest = [enclosingFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %lu",
				                                                        [item stringByDeletingPathExtension], (unsigned long)i++]];
				if (ext && [ext length] > 0)
					dest = [dest stringByAppendingPathExtension:ext];
			}
			[self.fileManager moveItemAtPath:subPath toPath:dest error:nil];
		}
	}
	[self.fileManager removeItemAtPath:expansionDirectory error:nil];
    
}

#pragma mark -
#pragma mark Accessors

- (NSString *) comment {
	return self.cdTrailer.comment;
}
- (void) setComment:(NSString *)comment {
	self.cdTrailer.comment = comment;
}

#pragma mark -
#pragma mark Delegate

- (void) setInvoker:(id)i {
	_invoker = i;
	if (_invoker)
		irtsIsCancelled = [self.invoker respondsToSelector:@selector(isCancelled)];
	else
		irtsIsCancelled = NO;
}

- (void) setDelegate:(id)d {
	_delegate = d;
	if (_delegate) {
		drtsDelegateWantsSizes = [_delegate respondsToSelector:@selector(zkDelegateWantsSizes)];
		drtsDidBeginZip = [_delegate respondsToSelector:@selector(onZKArchiveDidBeginZip:)];
		drtsDidBeginUnzip = [_delegate respondsToSelector:@selector(onZKArchiveDidBeginUnzip:)];
		drtsWillZipPath = [_delegate respondsToSelector:@selector(onZKArchive:willZipPath:)];
		drtsWillUnzipPath = [_delegate respondsToSelector:@selector(onZKArchive:willUnzipPath:)];
		drtsDidEndZip = [_delegate respondsToSelector:@selector(onZKArchiveDidEndZip:)];
		drtsDidEndUnzip = [_delegate respondsToSelector:@selector(onZKArchiveDidEndUnzip:)];
		drtsDidCancel = [_delegate respondsToSelector:@selector(onZKArchiveDidCancel:)];
		drtsDidFail = [_delegate respondsToSelector:@selector(onZKArchiveDidFail:)];
		drtsDidUpdateTotalSize = [_delegate respondsToSelector:@selector(onZKArchive:didUpdateTotalSize:)];
		drtsDidUpdateTotalCount = [_delegate respondsToSelector:@selector(onZKArchive:didUpdateTotalCount:)];
		drtsDidUpdateBytesWritten = [_delegate respondsToSelector:@selector(onZKArchive:didUpdateBytesWritten:)];
	} else {
		drtsDelegateWantsSizes = NO;
		drtsDidBeginZip = NO;
		drtsDidBeginUnzip = NO;
		drtsWillZipPath = NO;
		drtsWillUnzipPath = NO;
		drtsDidEndZip = NO;
		drtsDidEndUnzip = NO;
		drtsDidCancel = NO;
		drtsDidFail = NO;
		drtsDidUpdateTotalSize = NO;
		drtsDidUpdateTotalCount = NO;
		drtsDidUpdateBytesWritten = NO;
	}
}

- (BOOL) delegateWantsSizes {
	BOOL delegateWantsSizes = NO;
	if (drtsDelegateWantsSizes)
		delegateWantsSizes = [self.delegate zkDelegateWantsSizes];
	return delegateWantsSizes;
}

- (void) didBeginZip  {
	if (drtsDidBeginZip)
		[self.delegate onZKArchiveDidBeginZip:self];
}

- (void) didBeginUnzip  {
	if (drtsDidBeginUnzip)
		[self.delegate onZKArchiveDidBeginUnzip:self];
}

- (void) willZipPath:(NSString *)path {
	if (drtsWillZipPath)
		[self.delegate onZKArchive:self willZipPath:path];
}

- (void) willUnzipPath:(NSString *)path {
	if (drtsWillUnzipPath)
		[self.delegate onZKArchive:self willUnzipPath:path];
}

- (void) didEndZip {
	if (drtsDidEndZip)
		[self.delegate onZKArchiveDidEndZip:self];
}

- (void) didEndUnzip {
	if (drtsDidEndUnzip)
		[self.delegate onZKArchiveDidEndUnzip:self];
}

- (void) didCancel {
	if (drtsDidCancel)
		[self.delegate onZKArchiveDidCancel:self];
}

- (void) didFail {
	if (drtsDidFail)
		[self.delegate onZKArchiveDidFail:self];
}

- (void) didUpdateTotalSize:(NSNumber *)size {
	if (drtsDidUpdateTotalSize)
		[self.delegate onZKArchive:self didUpdateTotalSize:[size unsignedLongLongValue]];
}

- (void) didUpdateTotalCount:(NSNumber *)count {
	if (drtsDidUpdateTotalCount)
		[self.delegate onZKArchive:self didUpdateTotalCount:[count unsignedLongLongValue]];
}

- (void) didUpdateBytesWritten:(NSNumber *)byteCount {
	if (drtsDidUpdateBytesWritten)
		[self.delegate onZKArchive:self didUpdateBytesWritten:[byteCount unsignedLongLongValue]];
}

#pragma mark -
#pragma mark Setup

- (id) init {
	if (self = [super init]) {
		self.invoker = nil;
		self.delegate = nil;
		self.archivePath = nil;
		self.centralDirectory = [NSMutableArray array];
		self.fileManager = [NSFileManager new];
		self.cdTrailer = [ZKCDTrailer new];
		self.throttleThreadSleepTime = 0.0;
	}
	return self;
}

- (void) dealloc {
	self.invoker = nil;
	self.delegate = nil;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@\n\ttrailer:%@\n\tcentral directory:%@", self.archivePath, self.cdTrailer, self.centralDirectory];
}

@dynamic comment;

@end
