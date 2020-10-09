//
//  ZJMemoryCache.h
//  ZJDataCache
//
//  Created by ZJ on 2019/8/8.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZJDataCacheConfig;
@protocol ZJMemoryCache <NSObject>

@required

- (instancetype)initWithConfig:(ZJDataCacheConfig *)config;

- (nullable id)objectForKey:(id)key;

- (void)setObject:(nullable id)object forKey:(id)key;
- (void)setObject:(nullable id)object forKey:(id)key cost:(NSUInteger)cost;

- (void)removeObjectForKey:(id)key;
- (void)removeAllObjects;

@end

@interface ZJMemoryCache <KeyType, ObjectType> : NSCache <KeyType, ObjectType> <ZJMemoryCache>

@property (nonatomic, strong, readonly) ZJDataCacheConfig *config;

@end

NS_ASSUME_NONNULL_END
