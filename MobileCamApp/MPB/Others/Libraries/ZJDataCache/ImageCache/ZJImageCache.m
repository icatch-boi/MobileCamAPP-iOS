//
//  ZJImageCache.m
//  ZJDataCache
//
//  Created by ZJ on 2019/8/9.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "ZJImageCache.h"
#import "ZJMemoryCache.h"
#import "ZJDiskCache.h"
#import "UIImage+MemoryCacheCost.h"
#import "UIImage+MultiFormat.h"
#import "ZJImageCoderHelper.h"

@interface ZJImageCache ()

@property (nonatomic, strong) id<ZJMemoryCache> memCache;
@property (nonatomic, strong) id<ZJDiskCache> diskCache;
@property (nonatomic, copy, readwrite) ZJDataCacheConfig *config;
@property (nonatomic, copy, readwrite) NSString *diskCachePath;
@property (nonatomic, strong) dispatch_queue_t ioQueue;

@end

@implementation ZJImageCache

#pragma mark - Singleton, init, dealloc
+ (ZJImageCache *)sharedImageCache {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
    return [self initWithNamespace:@"default"];
}

- (instancetype)initWithNamespace:(NSString *)ns {
    return [self initWithNamespace:ns diskCacheDirectory:nil];
}

- (instancetype)initWithNamespace:(NSString *)ns diskCacheDirectory:(nullable NSString *)directory {
    return [self initWithNamespace:ns diskCacheDirectory:directory config:ZJDataCacheConfig.defaultCacheConfig];
}

- (instancetype)initWithNamespace:(NSString *)ns diskCacheDirectory:(nullable NSString *)directory config:(nullable ZJDataCacheConfig *)config {
    if (self = [super init]) {
        NSAssert(ns, @"Cache namespace should not be nil");
        
        _ioQueue = dispatch_queue_create("com.icatchtek.ImageCache", DISPATCH_QUEUE_SERIAL);
        
        if (config == nil) {
            config = ZJDataCacheConfig.defaultCacheConfig;
        }
        
        _config = [config copy];
        
        NSAssert([config.memoryCacheClass conformsToProtocol:@protocol(ZJMemoryCache)], @"Custom memory cache class must conform to `ZJMemoryCache' protocol");
        _memCache = [[config.memoryCacheClass alloc] initWithConfig:_config];
        
        if (directory != nil) {
            _diskCachePath = [directory stringByAppendingPathComponent:ns];
        } else {
            NSString *path = [[[self userCacheDirectory] stringByAppendingPathComponent:@"com.icatchtek.ImageCache"] stringByAppendingPathComponent:ns];
            _diskCachePath = path;
        }
        
        NSAssert([config.diskCacheClass conformsToProtocol:@protocol(ZJDiskCache)], @"Custom disk cache class must conform to `ZJDiskCache' protocol");
        _diskCache = [[config.diskCacheClass alloc] initWithCachePath:_diskCachePath config:_config];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Cache paths
- (nullable NSString *)cachePathForKey:(NSString *)key {
    if (key == nil) {
        return nil;
    }
    return [self.diskCache cachePathForKey:key];
}

- (nullable NSString *)userCacheDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

#pragma mark - Store Ops
- (void)storeImage:(UIImage *)image
            forKey:(NSString *)key
        completion:(ZJImageCacheNoParamsBlock)completionBlock {
    [self storeImage:image imageData:nil forKey:key toDisk:YES completion:completionBlock];
}

- (void)storeImage:(UIImage *)image
            forKey:(NSString *)key
            toDisk:(BOOL)toDisk
        completion:(nullable ZJImageCacheNoParamsBlock)completionBlock {
    [self storeImage:image imageData:nil forKey:key toDisk:toDisk completion:completionBlock];
}

- (void)storeImage:(UIImage *)image
         imageData:(NSData *)imageData
            forKey:(NSString *)key
            toDisk:(BOOL)toDisk
        completion:(ZJImageCacheNoParamsBlock)completionBlock {
    [self storeImage:image imageData:imageData forKey:key toMemory:YES toDisk:toDisk completion:completionBlock];
}

- (void)storeImage:(UIImage *)image
         imageData:(NSData *)imageData
            forKey:(NSString *)key
          toMemory:(BOOL)toMemory
            toDisk:(BOOL)toDisk
        completion:(ZJImageCacheNoParamsBlock)completionBlock {
    if (image == nil || key == nil) {
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    
    if (toMemory && self.config.shouldCacheImagesInMemory) {
        NSUInteger cost = image.zj_memoryCost;
        [self.memCache setObject:image forKey:key cost:cost];
    }
    
    if (toDisk) {
        dispatch_async(self.ioQueue, ^{
            @autoreleasepool {
                NSData *data = imageData;
                
                if (data == nil && image) {
                    BOOL imageIsPng;
                    if ([self CGImageContainsAlpha:image.CGImage]) {
                        imageIsPng = YES;
                    } else {
                        imageIsPng = NO;
                    }
                    
                    if (imageIsPng) {
                        data = UIImagePNGRepresentation(image);
                    } else {
                        data = UIImageJPEGRepresentation(image, (CGFloat)1.0);
                    }
                }
                
                [self _storeImageDataToDisk:data forKey:key];
            }
            
            if (completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock();
                });
            }
        });
    } else {
        if (completionBlock) {
            completionBlock();
        }
    }
}

- (void)storeImageToMemory:(UIImage *)image forKey:(NSString *)key {
    if (image == nil || key == nil) {
        return;
    }
    
    NSUInteger cost = image.zj_memoryCost;
    [self.memCache setObject:image forKey:key cost:cost];
}

- (void)storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key {
    if (imageData == nil || key == nil) {
        return;
    }
    
    dispatch_sync(self.ioQueue, ^{
        [self _storeImageDataToDisk:imageData forKey:key];
    });
}

- (void)_storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key {
    if (imageData == nil || key == nil) {
        return;
    }
    
    [self.diskCache setData:imageData forKey:key];
}

#pragma mark - Query & Retrieve Ops
- (void)diskImageExistsWithKey:(NSString *)key completion:(ZJImageCacheCheckCompletionBlock)completionBlock {
    dispatch_async(self.ioQueue, ^{
        BOOL exists = [self _diskImageDataExistsWithKey:key];
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(exists);
            });
        }
    });
}

- (BOOL)diskImageDataExistsWithKey:(NSString *)key {
    if (key == nil) {
        return NO;
    }
    
    __block BOOL exists = NO;
    dispatch_sync(self.ioQueue, ^{
        exists = [self _diskImageDataExistsWithKey:key];
    });
    
    return exists;
}

- (BOOL)_diskImageDataExistsWithKey:(NSString *)key {
    if (key == nil) {
        return NO;
    }
    
    return [self.diskCache containsDataForKey:key];
}

- (nullable NSData *)diskImageDataForKey:(NSString *)key {
    if (key == nil) {
        return nil;
    }
    
    __block NSData *imageData = nil;
    dispatch_sync(self.ioQueue, ^{
        imageData = [self diskImageDataBySearchingAllPathsForKey:key];
    });
    
    return imageData;
}

- (nullable UIImage *)imageFromMemoryCacheForKey:(NSString *)key {
    return [self.memCache objectForKey:key];
}

- (nullable UIImage *)imageFromDiskCacheForKey:(NSString *)key {
    UIImage *diskImage = [self diskImageForKey:key];
    if (diskImage && self.config.shouldCacheImagesInMemory) {
        NSUInteger cost = diskImage.zj_memoryCost;
        [self.memCache setObject:diskImage forKey:key cost:cost];
    }
    
    return diskImage;
}

- (UIImage *)imageFromCacheForKey:(NSString *)key {
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image) {
        return image;
    }
    
    image = [self imageFromDiskCacheForKey:key];
    return image;
}

- (nullable NSData *)diskImageDataBySearchingAllPathsForKey:(nullable NSString *)key {
    if (key == nil) {
        return nil;
    }
    
    NSData *data = [self.diskCache dataForKey:key];
    if (data) {
        return data;
    }
    
    if (self.additionalCachePathBlock) {
        NSString *filePath = self.additionalCachePathBlock(key);
        if (filePath) {
            data = [NSData dataWithContentsOfFile:filePath options:self.config.diskCacheReadingOptions error:nil];
        }
    }
    
    return data;
}

- (nullable UIImage *)diskImageForKey:(nullable NSString *)key {
    NSData *data = [self diskImageDataForKey:key];
    return [self diskImageForKey:key data:data];
}

- (nullable UIImage *)diskImageForKey:(nullable NSString *)key data:(nullable NSData *)data {
    if (data != nil) {
        UIImage *image = [UIImage zj_imageWithData:data];
        image = [self scaledImageForKey:key image:image];
        image = [ZJImageCoderHelper decodedImageWithImage:image];
        return image;
    } else {
        return nil;
    }
}

- (UIImage *)scaledImageForKey:(NSString *)key image:(UIImage *)image {
    return ZJScaledImageForKey(key, image);
}

#pragma mark - Remove Ops
- (void)removeImageForKey:(NSString *)key completion:(ZJImageCacheNoParamsBlock)completionBlock {
    [self removeImageForKey:key fromMemory:YES fromDisk:YES completion:completionBlock];
}

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk completion:(ZJImageCacheNoParamsBlock)completionBlock {
    [self removeImageForKey:key fromMemory:YES fromDisk:fromDisk completion:completionBlock];
}

- (void)removeImageForKey:(NSString *)key fromMemory:(BOOL)fromMemory fromDisk:(BOOL)fromDisk completion:(ZJImageCacheNoParamsBlock)completionBlock {
    if (key == nil) {
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    
    if (fromMemory && self.config.shouldCacheImagesInMemory) {
        [self.memCache removeObjectForKey:key];
    }
    
    if (fromDisk) {
        dispatch_async(self.ioQueue, ^{
            [self.diskCache removeDataForKey:key];
            
            if (completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock();
                });
            }
        });
    } else if (completionBlock) {
        completionBlock();
    }
}

- (void)removeImageFromMemoryForKey:(NSString *)key {
    if (key == nil) {
        return;
    }
    
    [self.memCache removeObjectForKey:key];
}

- (void)removeImageFromDiskForKey:(NSString *)key {
    if (key == nil) {
        return;
    }
    
    dispatch_sync(self.ioQueue, ^{
        [self _removeImageFromDiskForKey:key];
    });
}

- (void)_removeImageFromDiskForKey:(NSString *)key {
    if (key == nil) {
        return;
    }
    
    [self.diskCache removeDataForKey:key];
}

#pragma mark - Cache clean Ops
- (void)clearMemory {
    [self.memCache removeAllObjects];
}

- (void)clearDiskOnCompletion:(ZJImageCacheNoParamsBlock)completionBlock {
    dispatch_async(self.ioQueue, ^{
        [self.diskCache removeAllData];
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    });
}

- (void)deleteOldFilesWithCompletionBlock:(ZJImageCacheNoParamsBlock)completionBlock {
    dispatch_async(self.ioQueue, ^{
        [self.diskCache removeExpiredData];
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    });
}

#pragma mark - UIApplicationWillTerminateNotification
- (void)applicationWillTerminate:(NSNotification *)notification {
    [self deleteOldFilesWithCompletionBlock:nil];
}

#pragma mark - UIApplicationDidEnterBackgroundNotification
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (!self.config.shouldRemoveExpiredDataWhenEnterBackground) {
        return;
    }
    
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if (!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    
    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    [self deleteOldFilesWithCompletionBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

#pragma mark - Cache Info
- (NSUInteger)totalDiskSize {
    __block NSUInteger size = 0;
    dispatch_sync(self.ioQueue, ^{
        size = [self.diskCache totalSize];
    });
    return size;
}

- (NSUInteger)totalDiskCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.ioQueue, ^{
        count = [self.diskCache totalCount];
    });
    return count;
}

- (void)calculateSizeWithCompletionBlock:(ZJImageCacheCalculateSizeBlock)completionBlock {
    dispatch_async(self.ioQueue, ^{
        NSUInteger fileCount = [self.diskCache totalCount];
        NSUInteger totalSize = [self.diskCache totalSize];
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(fileCount, totalSize);
            });
        }
    });
}

#pragma mark - Helper
- (BOOL)CGImageContainsAlpha:(CGImageRef)cgImage {
    if (!cgImage) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

inline UIImage *ZJScaledImageForKey(NSString *key, UIImage *image) {
    if (!image) {
        return nil;
    }
    
    if ([image.images count] > 0) {
        NSMutableArray *scaledImages = [NSMutableArray array];
        
        for (UIImage *tempImage in image.images) {
            [scaledImages addObject:ZJScaledImageForKey(key, tempImage)];
        }
        
        return [UIImage animatedImageWithImages:scaledImages duration:image.duration];
    }
    else {
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
            CGFloat scale = 1.0;
            if (key.length >= 8) {
                // Search @2x. at the end of the string, before a 3 to 4 extension length (only if key len is 8 or more @2x. + 4 len ext)
                NSRange range = [key rangeOfString:@"@2x." options:0 range:NSMakeRange(key.length - 8, 5)];
                if (range.location != NSNotFound) {
                    scale = 2.0;
                }
            }
            
            UIImage *scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
            image = scaledImage;
        }
        return image;
    }
}

@end
