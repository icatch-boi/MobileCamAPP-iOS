//
//  ZJImageCacheCommon.h
//  ZJDataCache
//
//  Created by ZJ on 2019/8/9.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#ifndef ZJImageCacheCommon_h
#define ZJImageCacheCommon_h

typedef void(^ZJImageCacheNoParamsBlock)(void);
typedef void(^ZJImageCacheCheckCompletionBlock)(BOOL isInCache);
typedef void(^ZJImageCacheCalculateSizeBlock)(NSUInteger fileCount, NSUInteger totalSize);
typedef NSString * _Nullable (^ZJImageCacheAdditionalCachePathBlock)(NSString * _Nonnull key);

FOUNDATION_EXPORT UIImage * _Nullable ZJScaledImageForKey(NSString * _Nullable key, UIImage * _Nullable image);

#endif /* ZJImageCacheCommon_h */
