//
//  ZJImageCache.h
//  ZJDataCache
//
//  Created by ZJ on 2019/8/9.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZJDataCacheConfig.h"
#import "ZJImageCacheCommon.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZJImageCache : NSObject

#pragma mark - Properties

@property (nonatomic, copy, readonly) ZJDataCacheConfig *config;

@property (nonatomic, copy, readonly) NSString *diskCachePath;

@property (nonatomic, copy, nullable) ZJImageCacheAdditionalCachePathBlock additionalCachePathBlock;

#pragma mark - Singleton & initialization
@property (nonatomic, class, readonly, nonnull) ZJImageCache *sharedImageCache;

- (instancetype)initWithNamespace:(NSString *)ns;
- (instancetype)initWithNamespace:(NSString *)ns
               diskCacheDirectory:(nullable NSString *)directory;
- (instancetype)initWithNamespace:(NSString *)ns
               diskCacheDirectory:(nullable NSString *)directory
                           config:(nullable ZJDataCacheConfig *)config;

#pragma mark - Cache paths
- (nullable NSString *)cachePathForKey:(NSString *)key;

#pragma mark - Store Ops
- (void)storeImage:(nullable UIImage *)image
            forKey:(nullable NSString *)key
        completion:(nullable ZJImageCacheNoParamsBlock)completionBlock;

- (void)storeImage:(nullable UIImage *)image
            forKey:(nullable NSString *)key
            toDisk:(BOOL)toDisk
        completion:(nullable ZJImageCacheNoParamsBlock)completionBlock;

- (void)storeImage:(nullable UIImage *)image
         imageData:(nullable NSData *)imageData
            forKey:(nullable NSString *)key
            toDisk:(BOOL)toDisk
        completion:(nullable ZJImageCacheNoParamsBlock)completionBlock;

- (void)storeImageToMemory:(nullable UIImage *)image
                    forKey:(nullable NSString *)key;

- (void)storeImageDataToDisk:(nullable NSData *)imageData
                    forKey:(nullable NSString *)key;

#pragma mark - Contains & Check Ops
- (void)diskImageExistsWithKey:(nullable NSString *)key
                    completion:(nullable ZJImageCacheCheckCompletionBlock)completionBlock;

- (BOOL)diskImageDataExistsWithKey:(nullable NSString *)key;

#pragma mark - Query & Retrieve Ops
- (nullable NSData *)diskImageDataForKey:(nullable NSString *)key;
- (nullable UIImage *)imageFromMemoryCacheForKey:(nullable NSString *)key;
- (nullable UIImage *)imageFromDiskCacheForKey:(nullable NSString *)key;
- (nullable UIImage *)imageFromCacheForKey:(nullable NSString *)key;

#pragma mark - Remove Ops
- (void)removeImageForKey:(nullable NSString *)key
               completion:(nullable ZJImageCacheNoParamsBlock)completionBlock;
- (void)removeImageForKey:(nullable NSString *)key
                 fromDisk:(BOOL)fromDisk
               completion:(nullable ZJImageCacheNoParamsBlock)completionBlock;
- (void)removeImageFromMemoryForKey:(nullable NSString *)key;
- (void)removeImageFromDiskForKey:(nullable NSString *)key;

#pragma mark - Cache clean Ops
- (void)clearMemory;
- (void)clearDiskOnCompletion:(nullable ZJImageCacheNoParamsBlock)completionBlock;
- (void)deleteOldFilesWithCompletionBlock:(nullable ZJImageCacheNoParamsBlock)completionBlock;

#pragma mark - Cache Info
- (NSUInteger)totalDiskSize;
- (NSUInteger)totalDiskCount;

- (void)calculateSizeWithCompletionBlock:(nullable ZJImageCacheCalculateSizeBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
