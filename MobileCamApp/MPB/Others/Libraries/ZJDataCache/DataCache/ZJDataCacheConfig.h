//
//  ZJDataCacheConfig.h
//  ZJDataCache
//
//  Created by ZJ on 2019/8/8.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZJDataCacheConfigExpireType) {
    ZJDataCacheConfigExpireTypeAccessData,
    ZJDataCacheConfigExpireTypeModificationData,
};

@interface ZJDataCacheConfig : NSObject <NSCopying>

@property (nonatomic, class, readonly, nonnull) ZJDataCacheConfig *defaultCacheConfig;

@property (nonatomic, assign) BOOL shouldDisableiCloud;
@property (nonatomic, assign) BOOL shouldCacheImagesInMemory;
@property (nonatomic, assign) BOOL shouldUseWeakMemoryCache;
@property (nonatomic, assign) BOOL shouldRemoveExpiredDataWhenEnterBackground;

@property (nonatomic, assign) NSDataReadingOptions diskCacheReadingOptions;
@property (nonatomic, assign) NSDataWritingOptions diskCacheWritingOptions;

@property (nonatomic, assign) NSTimeInterval maxDiskAge;
@property (nonatomic, assign) NSUInteger maxDiskSize;

@property (nonatomic, assign) NSUInteger maxMemoryCost;
@property (nonatomic, assign) NSUInteger maxMemoryCount;

@property (nonatomic, assign) ZJDataCacheConfigExpireType diskCacheExpireType;

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, assign) Class memoryCacheClass;
@property (nonatomic, assign) Class diskCacheClass;

@end

NS_ASSUME_NONNULL_END
