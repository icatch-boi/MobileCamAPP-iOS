//
//  ZJMemoryCache.m
//  ZJDataCache
//
//  Created by ZJ on 2019/8/8.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "ZJMemoryCache.h"
#import "ZJDataCacheConfig.h"
#import "ZJInternalMacros.h"
#import "UIImage+MemoryCacheCost.h"

static void * ZJMemoryCacheContext = &ZJMemoryCacheContext;

@interface ZJMemoryCache <KeyType, ObjectType> ()

@property (nonatomic, strong) ZJDataCacheConfig *config;
@property (nonatomic, strong) NSMapTable<KeyType, ObjectType> *weakCache;
@property (nonatomic, strong) dispatch_semaphore_t weakCacheLock;

@end

@implementation ZJMemoryCache

- (void)dealloc {
    [_config removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCost))];
    [_config removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCount))];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _config = [[ZJDataCacheConfig alloc] init];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithConfig:(ZJDataCacheConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.weakCache = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
    self.weakCacheLock = dispatch_semaphore_create(1);
    
    ZJDataCacheConfig *config = self.config;
    self.totalCostLimit = config.maxMemoryCost;
    self.countLimit = config.maxMemoryCount;
    
    [config addObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCost)) options:0 context:ZJMemoryCacheContext];
    [config addObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCount)) options:0 context:ZJMemoryCacheContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [super removeAllObjects];
}

- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g {
    [super setObject:obj forKey:key cost:g];
    
    if (!self.config.shouldUseWeakMemoryCache) {
        return;
    }
    
    if (key && obj) {
        ZJ_LOCK(self.weakCacheLock);
        [self.weakCache setObject:obj forKey:key];
        ZJ_UNLOCK(self.weakCacheLock);
    }
}

- (id)objectForKey:(id)key {
    id obj = [super objectForKey:key];
    if (!self.config.shouldUseWeakMemoryCache) {
        return obj;
    }
    
    if (key && !obj) {
        ZJ_LOCK(self.weakCacheLock);
        obj = [self.weakCache objectForKey:key];
        ZJ_UNLOCK(self.weakCacheLock);
        
        if (obj) {
            // Sync cache
            NSUInteger cost = 0;
            if ([obj isKindOfClass:[UIImage class]]) {
                cost = [(UIImage *)obj zj_memoryCost];
            }
            [super setObject:obj forKey:key cost:cost];
        }
    }
    
    return obj;
}

- (void)removeObjectForKey:(id)key {
    [super removeObjectForKey:key];
    if (!self.config.shouldUseWeakMemoryCache) {
        return;
    }
    
    if (key) {
        ZJ_LOCK(self.weakCacheLock);
        [self.weakCache removeObjectForKey:key];
        ZJ_UNLOCK(self.weakCacheLock);
    }
}

- (void)removeAllObjects {
    [super removeAllObjects];
    if (!self.config.shouldUseWeakMemoryCache) {
        return;
    }
    
    ZJ_LOCK(self.weakCacheLock);
    [self.weakCache removeAllObjects];
    ZJ_UNLOCK(self.weakCacheLock);
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == ZJMemoryCacheContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(maxMemoryCost))]) {
            self.totalCostLimit = self.config.maxMemoryCost;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(maxMemoryCount))]) {
            self.countLimit = self.config.maxMemoryCount;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
