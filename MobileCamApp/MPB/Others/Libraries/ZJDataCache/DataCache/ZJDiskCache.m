//
//  ZJDiskCache.m
//  ZJDataCache
//
//  Created by ZJ on 2019/8/8.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "ZJDiskCache.h"
#import "ZJDataCacheConfig.h"
#import <CommonCrypto/CommonDigest.h>

@interface ZJDiskCache ()

@property (nonatomic, copy) NSString *diskCachePath;
@property (nonatomic, strong) NSFileManager *fileManager;

@end

@implementation ZJDiskCache

- (instancetype)init {
    NSAssert(NO, @"Use `initWithCachePath:` with the disk cache path");
    return nil;
}

#pragma mark - ZJCachePathForKeyDiskCache Protocol
- (instancetype)initWithCachePath:(NSString *)cachePath config:(ZJDataCacheConfig *)config {
    if (self = [super init]) {
        _diskCachePath = cachePath;
        _config = config;
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    if (self.config.fileManager) {
        self.fileManager = self.config.fileManager;
    } else {
        self.fileManager = [NSFileManager new];
    }
}

- (BOOL)containsDataForKey:(NSString *)key {
    NSParameterAssert(key);
    NSString *filePath = [self cachePathForKey:key];
    BOOL exists = [self.fileManager fileExistsAtPath:filePath];
    
    if (!exists) {
        exists = [self.fileManager fileExistsAtPath:filePath.stringByDeletingPathExtension];
    }
    
    return exists;
}

- (NSData *)dataForKey:(NSString *)key {
    NSParameterAssert(key);
    NSString *filePath = [self cachePathForKey:key];
    NSData *data = [NSData dataWithContentsOfFile:filePath options:self.config.diskCacheReadingOptions error:nil];
    if (data) {
        return data;
    }
    
    data = [NSData dataWithContentsOfFile:filePath.stringByDeletingPathExtension options:self.config.diskCacheReadingOptions error:nil];
    if (data) {
        return data;
    }
    
    return nil;
}

- (void)setData:(NSData *)data forKey:(NSString *)key {
    NSParameterAssert(data);
    NSParameterAssert(key);
    
    if (![self.fileManager fileExistsAtPath:self.diskCachePath]) {
        [self.fileManager createDirectoryAtPath:self.diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    NSString *cachePathForKey = [self cachePathForKey:key];
    NSURL *fileURL = [NSURL fileURLWithPath:cachePathForKey];
    
    [data writeToURL:fileURL options:self.config.diskCacheWritingOptions error:nil];
    
    // disable iColud backup
    if (self.config.shouldDisableiCloud) {
        [fileURL setResourceValue:@YES forKey:NSURLIsExecutableKey error:nil];
    }
}

- (void)removeDataForKey:(NSString *)key {
    NSParameterAssert(key);
    NSString *filePath = [self cachePathForKey:key];
    [self.fileManager removeItemAtPath:filePath error:nil];
}

- (void)removeAllData {
    [self.fileManager removeItemAtPath:self.diskCachePath error:nil];
    [self.fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
}

- (void)removeExpiredData {
    NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
    
    NSURLResourceKey cacheContentDateKey = NSURLContentModificationDateKey;
    switch (self.config.diskCacheExpireType) {
        case ZJDataCacheConfigExpireTypeAccessData:
            cacheContentDateKey = NSURLContentAccessDateKey;
            break;
            
        case ZJDataCacheConfigExpireTypeModificationData:
            cacheContentDateKey = NSURLContentModificationDateKey;
            break;
            
        default:
            break;
    }
    
    NSArray<NSString *> *resourceKeys = @[NSURLIsDirectoryKey, cacheContentDateKey, NSURLTotalFileAllocatedSizeKey];
    
    NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:resourceKeys
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];
    NSDate *expirationDate = (self.config.maxDiskAge < 0) ? nil : [NSDate dateWithTimeIntervalSinceNow:-self.config.maxDiskAge];
    NSMutableDictionary<NSURL *, NSDictionary<NSString *, id> *> *cacheFiles = [NSMutableDictionary dictionary];
    NSUInteger currentCacheSize = 0;
    
    NSMutableArray<NSURL *> *urlsToDelete = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileEnumerator) {
        NSError *error;
        NSDictionary<NSString *, id> *resoureValues = [fileURL resourceValuesForKeys:resourceKeys error:&error];
        
        if (error || !resoureValues || [resoureValues[NSURLIsDirectoryKey] boolValue]) {
            continue;
        }
        
        NSDate *modifiedDate = resoureValues[cacheContentDateKey];
        if (expirationDate && [[modifiedDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
            [urlsToDelete addObject:fileURL];
            continue;
        }
        
        NSNumber *totalAllocatedSize = resoureValues[NSURLTotalFileAllocatedSizeKey];
        currentCacheSize += totalAllocatedSize.unsignedIntegerValue;
        cacheFiles[fileURL] = resoureValues;
    }
    
    for (NSURL *fileURL in urlsToDelete) {
        [self.fileManager removeItemAtURL:fileURL error:nil];
    }
    
    NSUInteger maxDiskSize = self.config.maxDiskSize;
    if (maxDiskSize > 0 && currentCacheSize > maxDiskSize) {
        const NSUInteger desiredCacheSize = maxDiskSize / 2;
        
        NSArray<NSURL *> *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                                 usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                                                                     return [obj1[cacheContentDateKey] compare:obj2[cacheContentDateKey]];
                                                                 }];
        
        for (NSURL *fileURL in sortedFiles) {
            if ([self.fileManager removeItemAtURL:fileURL error:nil]) {
                NSDictionary<NSString *, id> *resourceValues = cacheFiles[fileURL];
                NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                currentCacheSize -= totalAllocatedSize.unsignedIntegerValue;
                
                if (currentCacheSize < desiredCacheSize) {
                    break;
                }
            }
        }
    }
}

- (NSString *)cachePathForKey:(NSString *)key {
    NSParameterAssert(key);
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

- (NSUInteger)totalSize {
    NSUInteger size = 0;
    NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator) {
        NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary<NSString *, id> *attrs = [self.fileManager attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    
    return size;
}

- (NSUInteger)totalCount {
    NSUInteger count = 0;
    NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
    count = fileEnumerator.allObjects.count;
    return count;
}

#pragma mark - Cache paths
- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path {
    NSString *fileName = ZJDiskCacheFileNameForKey(key);
    return [path stringByAppendingPathComponent:fileName];
}

- (void)moveCacheDirectoryFromPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    NSParameterAssert(srcPath);
    NSParameterAssert(dstPath);
    if ([srcPath isEqualToString:dstPath]) {
        return;
    }
    
    BOOL isDirectory;
    if (![self.fileManager fileExistsAtPath:srcPath isDirectory:&isDirectory] || !isDirectory) {
        return;
    }
    
    if (![self.fileManager fileExistsAtPath:dstPath isDirectory:&isDirectory] || !isDirectory) {
        if (!isDirectory) {
            [self.fileManager removeItemAtPath:dstPath error:nil];
        }
        
        NSString *dstParentPath = [dstPath stringByDeletingLastPathComponent];
        if (![self.fileManager fileExistsAtPath:dstParentPath]) {
            [self.fileManager createDirectoryAtPath:dstParentPath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        [self.fileManager moveItemAtPath:srcPath toPath:dstPath error:nil];
    } else {
        NSDirectoryEnumerator *dirEnumerator = [self.fileManager enumeratorAtPath:srcPath];
        NSString *file;
        while ((file = [dirEnumerator nextObject])) {
            [self.fileManager moveItemAtPath:[srcPath stringByAppendingPathComponent:file] toPath:[dstPath stringByAppendingPathComponent:file] error:nil];
        }
        
        [self.fileManager removeItemAtPath:srcPath error:nil];
    }
}

#pragma mark - Hash

#define ZJ_MAX_FILE_EXTENSION_LENGTH (NAME_MAX - CC_MD5_DIGEST_LENGTH * 2 - 1)

static inline NSString * _Nonnull ZJDiskCacheFileNameForKey(NSString * _Nullable key) {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSURL *keyURL = [NSURL URLWithString:key];
    NSString *ext = keyURL ? keyURL.pathExtension : key.pathExtension;
    if (ext.length > ZJ_MAX_FILE_EXTENSION_LENGTH) {
        ext = nil;
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@", r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15], ext.length == 0 ? @"" : [NSString stringWithFormat:@".%@", ext]];
    return fileName;
}

@end
