//
//  ZJDataCacheConfig.m
//  ZJDataCache
//
//  Created by ZJ on 2019/8/8.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "ZJDataCacheConfig.h"
#import "ZJMemoryCache.h"
#import "ZJDiskCache.h"

static ZJDataCacheConfig *_defaultCacheConfig = nil;
static const NSInteger kDefauleCacheMaxDiskAge = 60 * 60 * 24 * 7;

@implementation ZJDataCacheConfig

+ (ZJDataCacheConfig *)defaultCacheConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultCacheConfig = [ZJDataCacheConfig new];
    });
    
    return _defaultCacheConfig;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _shouldDisableiCloud = YES;
        _shouldCacheImagesInMemory = YES;
        _shouldUseWeakMemoryCache = YES;
        _shouldRemoveExpiredDataWhenEnterBackground = YES;
        _diskCacheReadingOptions = 0;
        _diskCacheWritingOptions = NSDataWritingAtomic;
        _maxDiskAge = kDefauleCacheMaxDiskAge;
        _maxDiskSize = 0;
        _diskCacheExpireType = ZJDataCacheConfigExpireTypeModificationData;
        _memoryCacheClass = [ZJMemoryCache class];
        _diskCacheClass = [ZJDiskCache class];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ZJDataCacheConfig *config = [[[self class] allocWithZone:zone] init];
    
    config.shouldDisableiCloud = self.shouldDisableiCloud;
    config.shouldCacheImagesInMemory = self.shouldCacheImagesInMemory;
    config.shouldUseWeakMemoryCache = self.shouldUseWeakMemoryCache;
    config.shouldRemoveExpiredDataWhenEnterBackground = self.shouldRemoveExpiredDataWhenEnterBackground;
    config.diskCacheReadingOptions = self.diskCacheReadingOptions;
    config.diskCacheWritingOptions = self.diskCacheWritingOptions;
    config.maxDiskAge = self.maxDiskAge;
    config.maxDiskSize = self.maxDiskSize;
    config.maxMemoryCost = self.maxMemoryCost;
    config.maxMemoryCount = self.maxMemoryCount;
    config.diskCacheExpireType = self.diskCacheExpireType;
    config.fileManager = self.fileManager;
    config.memoryCacheClass = self.memoryCacheClass;
    config.diskCacheClass = self.diskCacheClass;
    
    return config;
}

@end
