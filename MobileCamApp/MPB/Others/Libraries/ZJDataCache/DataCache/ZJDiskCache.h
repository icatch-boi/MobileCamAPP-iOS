//
//  ZJDiskCache.h
//  ZJDataCache
//
//  Created by ZJ on 2019/8/8.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ZJDataCacheConfig;
@protocol ZJDiskCache <NSObject>

@required

- (instancetype)initWithCachePath:(NSString *)cachePath config:(ZJDataCacheConfig *)config;
- (BOOL)containsDataForKey:(NSString *)key;

- (nullable NSData *)dataForKey:(NSString *)key;
- (void)setData:(nullable NSData *)data forKey:(nonnull NSString *)key;

- (void)removeDataForKey:(NSString *)key;

- (void)removeAllData;

- (void)removeExpiredData;

- (nullable NSString *)cachePathForKey:(NSString *)key;

- (NSUInteger)totalCount;

- (NSUInteger)totalSize;

@end

@interface ZJDiskCache : NSObject <ZJDiskCache>

@property (nonatomic, strong, readonly, nonnull) ZJDataCacheConfig *config;

- (instancetype)init NS_UNAVAILABLE;

- (void)moveCacheDirectoryFromPath:(NSString *)srcPath toPath:(NSString *)dstPath;

@end

NS_ASSUME_NONNULL_END
